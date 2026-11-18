use cosmic::iced::futures::{
    SinkExt, {self},
};
use cosmic::iced::{Subscription, stream};
use notify::{Config, EventKind, RecommendedWatcher, RecursiveMode, Watcher};
use std::fmt::Debug;
use std::hash::Hash;
use tokio::sync::mpsc;

#[derive(Debug, Clone, Copy)]
pub enum Event {
    Changed,
}

pub fn desktop_files<I: 'static + Hash + Copy + Send + Sync + Debug>(
    id: I,
) -> cosmic::iced::Subscription<Event> {
    Subscription::run_with(id, |_| {
        stream::channel(
            50,
            move |mut output: futures::channel::mpsc::Sender<Event>| async move {
                let (tx, mut rx) = mpsc::channel(1);
                let watcher = RecommendedWatcher::new(
                    move |res: Result<notify::Event, notify::Error>| {
                        if let Ok(event) = res
                            && matches!(
                                event.kind,
                                EventKind::Create(_) | EventKind::Modify(_) | EventKind::Remove(_)
                            )
                            && event.paths.iter().any(|path| {
                                path.extension().is_some_and(|ext| ext == "desktop")
                                    || path.ends_with(".changed")
                            })
                        {
                            let _ = tx.try_send(());
                        }
                    },
                    Config::default(),
                );

                if let Ok(mut watcher) = watcher {
                    for path in cosmic::desktop::fde::default_paths() {
                        let _ = watcher.watch(&path, RecursiveMode::Recursive);
                        if path.ends_with("flatpak/exports/share/applications")
                            && let Some(installation) = path.ancestors().nth(3)
                        {
                            // Flatpak signals changes here even when exports are created later.
                            let _ = watcher.watch(installation, RecursiveMode::NonRecursive);
                        }
                    }

                    let quiet_period = std::time::Duration::from_millis(300);
                    while rx.recv().await.is_some() {
                        loop {
                            match tokio::time::timeout(quiet_period, rx.recv()).await {
                                Ok(Some(())) => continue,
                                Ok(None) => return,
                                Err(_) => break,
                            }
                        }
                        if output.send(Event::Changed).await.is_err() {
                            return;
                        }
                    }
                }

                futures::future::pending().await
            },
        )
    })
}
