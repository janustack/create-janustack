use crate::{package_manager::PackageManager, template::Template};
use clap::{ArgAction, Parser};

#[derive(Parser, Debug)]
#[command(
  name = "create-janustack",
  about,
  long_about = None,
  version,
)]
pub struct Args {
    #[arg(help = "Project name")]
    pub project_name: Option<String>,

    #[arg(short, long, help = "Package manager to use")]
    pub manager: Option<PackageManager>,

    #[arg(short, long, help = "Project template to use")]
    pub template: Option<Template>,
    
    #[arg(long, help = "Initialize a Git repository", action = ArgAction::SetTrue)]
    pub git: bool,

    #[arg(short, long, help = "Force overwrite of existing files", action = ArgAction::SetTrue)]
    pub force: bool,
}

impl Default for Args {
    fn default() -> Self {
        Self {
            project_name: Some("janustack-project".to_string()),
            manager: Some(PackageManager::Bun),
            template: Some(Template::Janext),
            git: false,
            force: false,
        }
    }
}
