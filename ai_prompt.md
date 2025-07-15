Some files that are used in my cli scaffolding tool.
What I want: I want the user to be give an option to optionally initialize a Git repository While they are going through the steps they will be given these aditional steps that i want implemented:

Example:
```cli tool in terminal
> - Git
Git (Default)
No Git

// Final step the of the cli tool

> - Install
Install Dependencies (Default)
Skip Install

// Closing

Project template successfully scaffolded!
```

args.rs:
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

    #[arg(short, long, help = "Force overwrite of existing files", action = ArgAction::SetTrue)]
    pub force: bool,
}

impl Default for Args {
    fn default() -> Self {
        Self {
            project_name: Some("janustack-project".to_string()),
            manager: Some(PackageManager::Bun),
            template: Some(Template::Janext),
            force: false,
        }
    }
}

lib.rs:
use anyhow::Context;
use clap::Parser;
use std::{ffi::OsString, fs, process::exit};
use utils::prompts;

use crate::{
    package_manager::PackageManager,
    template::{JanudocsSubTemplate, Template},
    utils::colors::*,
};

mod args;
mod package_manager;
mod template;
pub mod utils;

pub fn run<I, A>(args: I, bin_name: Option<String>, detected_manager: Option<String>)
where
    I: IntoIterator<Item = A>,
    A: Into<OsString> + Clone,
{
    if let Err(e) = run_cli(args, bin_name, detected_manager) {
        println!();
        eprintln!("\n {BOLD}{RED}error{RESET}: {e:#}\n");
        exit(1);
    }
}

fn run_cli<I, A>(
    args: I,
    bin_name: Option<String>,
    detected_manager: Option<String>,
) -> anyhow::Result<()>
where
    I: IntoIterator<Item = A>,
    A: Into<OsString> + Clone,
{
    let detected_manager = detected_manager.and_then(|p| p.parse::<PackageManager>().ok());
    // Clap will auto parse the `bin_name` as the first argument, so we need to add it to the args
    let args = args::Args::parse_from(
        std::iter::once(OsString::from(bin_name.unwrap_or_default()))
            .chain(args.into_iter().map(Into::into)),
    );

    handle_brand_text("\nWelcome to Janustack\n");
    let defaults = args::Args::default();
    let args::Args {
        manager,
        project_name,
        template,
        force,
    } = args;

    let cwd = std::env::current_dir()?;
    let mut default_project_name = "janustack-project";
    let project_name = match project_name {
        Some(name) => to_valid_pkg_name(&name),
        None => loop {
            let input = prompts::input(
                "Enter the name for your new project (relative to current directory)\n",
                Some(default_project_name),
                false,
            )?
            .trim()
            .to_string();
            if !is_valid_pkg_name(&input) {
                eprintln!(
                    "{BOLD}{RED}✘{RESET} Invalid project name: {BOLD}{YELLOW}{input}{RESET}, {}",
                    "package name should only include lowercase alphanumeric character and hyphens \"-\" and doesn't start with numbers"
                );
                default_project_name = to_valid_pkg_name(&input).leak();
                continue;
            };
            break input;
        },
    };
    let target_dir = cwd.join(&project_name);

    if target_dir.exists() && target_dir.read_dir()?.next().is_some() {
        let overwrite = force
            || prompts::confirm(
                &format!(
                    "{} directory is not empty, do you want to overwrite?",
                    if target_dir == cwd {
                        "Current".to_string()
                    } else {
                        target_dir
                            .file_name()
                            .unwrap()
                            .to_string_lossy()
                            .to_string()
                    }
                ),
                false,
            )?;
        if !overwrite {
            eprintln!("{BOLD}{RED}✘{RESET} Directory is not empty, Operation Cancelled");
            exit(1);
        }
    };

    let pkg_manager = manager.unwrap_or(match detected_manager {
        Some(manager) => manager,
        None => defaults.manager.context("default manager not set")?,
    });

    let templates_no_flavors = pkg_manager.templates_no_flavors();

    let template = match template {
        Some(template) => template,
        None => {
            let selected_template =
                prompts::select("Select a framework:", &templates_no_flavors, Some(0))?.unwrap();

            match selected_template {
                Template::Janudocs(None) => {
                    let sub_templates =
                        vec![JanudocsSubTemplate::React, JanudocsSubTemplate::Solid];

                    let sub_template =
                        prompts::select("Select an Janudocs template:", &sub_templates, Some(0))?
                            .unwrap();

                    Template::Janudocs(Some(*sub_template))
                }
                _ => *selected_template,
            }
        }
    };

    if target_dir.exists() {
        #[inline(always)]
        fn clean_dir(dir: &std::path::PathBuf) -> anyhow::Result<()> {
            for entry in fs::read_dir(dir)?.flatten() {
                let path = entry.path();
                if entry.file_type()?.is_dir() {
                    if entry.file_name() != ".git" {
                        clean_dir(&path)?;
                        std::fs::remove_dir(path)?;
                    }
                } else {
                    fs::remove_file(path)?;
                }
            }
            Ok(())
        }
        clean_dir(&target_dir)?;
    } else {
        fs::create_dir_all(&target_dir)?;
    }

    // Render the template
    template.render(&target_dir, pkg_manager, &project_name, &project_name)?;

    handle_brand_text("\nNext steps:\n");

    if target_dir != cwd {
        handle_brand_text(&format!(
            "1. cd {} \n",
            if project_name.contains(' ') {
                format!("\"{project_name}\"")
            } else {
                project_name.to_string()
            }
        ));
    }
    if let Some(cmd) = pkg_manager.install_cmd() {
        handle_brand_text(&format!("2. {cmd}\n"));
    }
    handle_brand_text(&format!("3. {}\n", get_run_cmd(&pkg_manager, &template)));

    handle_brand_text("\nUpdate all dependencies:\n");
    handle_brand_text(&format!("{} pons -r\n", pkg_manager.update_cmd()));

    handle_brand_text("\nLike create-janustack? Give a star on GitHub:\n");
    handle_brand_text(&format!("https://github.com/janustack/create-janustack"));

    Ok(())
}

fn is_valid_pkg_name(project_name: &str) -> bool {
    let mut chars = project_name.chars().peekable();
    !project_name.is_empty()
        && !chars.peek().map(|c| c.is_ascii_digit()).unwrap_or_default()
        && !chars.any(|ch| !(ch.is_alphanumeric() || ch == '-' || ch == '_') || ch.is_uppercase())
}

fn to_valid_pkg_name(project_name: &str) -> String {
    let ret = project_name
        .trim()
        .to_lowercase()
        .replace([':', ';', ' ', '~'], "-")
        .replace(['.', '\\', '/'], "");

    let ret = ret
        .chars()
        .skip_while(|ch| ch.is_ascii_digit() || *ch == '-')
        .collect::<String>();

    if ret.is_empty() || !is_valid_pkg_name(&ret) {
        "janustack-project".to_string()
    } else {
        ret
    }
}

fn get_run_cmd(pkg_manager: &PackageManager, template: &Template) -> &'static str {
    match template {
        _ => pkg_manager.default_cmd(),
    }
}

main.rs:
// src/main.rs
use std::{env::args_os, ffi::OsStr, path::Path};

fn main() {
    let mut args = args_os().peekable();
    let mut is_cargo = false;
    let bin_name = match args
        .next()
        .as_deref()
        .map(Path::new)
        .and_then(Path::file_stem)
        .and_then(OsStr::to_str)
    {
        Some("cargo-create-janustack") => {
            is_cargo = true;
            if args.peek().and_then(|s| s.to_str()) == Some("create-janustack") {
                args.next();
                Some("cargo create-janustack".into())
            } else {
                Some("cargo-create-janustack".into())
            }
        }
        Some(stem) => Some(stem.to_string()),
        None => None,
    };
    create_janustack::run(
        args,
        bin_name,
        if is_cargo { Some("cargo".into()) } else { None },
    );
}

template.rs:
use std::{collections::HashMap, fmt::Display, fs, path, str::FromStr};

use crate::{
    package_manager::PackageManager,
    utils::{colors::*, lte},
};

use rust_embed::RustEmbed;
use std::any::TypeId;
use std::mem::transmute;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
#[derive(RustEmbed)]
#[folder = "templates"]
#[allow(clippy::upper_case_acronyms, non_camel_case_types)]
struct EMBEDDED_TEMPLATES;

pub(crate) trait Displayable {
    fn display_text(&self) -> &str;
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum JanudocsSubTemplate {
    React,
    Solid,
}

impl JanudocsSubTemplate {
    pub(crate) fn to_simple_string(&self) -> &str {
        match self {
            JanudocsSubTemplate::React => "react",
            JanudocsSubTemplate::Solid => "solid",
        }
    }
}

impl Displayable for JanudocsSubTemplate {
    fn display_text(&self) -> &'static str {
        match self {
            JanudocsSubTemplate::React => "\x1b[36mReact\x1b[0m",
            JanudocsSubTemplate::Solid => "\x1b[38;2;68;206;246mSolid\x1b[0m",
        }
    }
}

impl Display for JanudocsSubTemplate {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        fmt_sub_template(self, f)
    }
}

impl FromStr for JanudocsSubTemplate {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let map: HashMap<&str, JanudocsSubTemplate> = HashMap::from([
            ("react", JanudocsSubTemplate::React),
            ("solid", JanudocsSubTemplate::Solid),
        ]);
        match map.get(s) {
            Some(template) => Ok(*template),
            None => Err(format!("{s} is not a valid Janudocs template.")),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum Template {
    Janext,
    Janudocs(Option<JanudocsSubTemplate>),
}

impl Default for Template {
    fn default() -> Self {
        Template::Janext
    }
}

impl Display for Template {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Template::Janext => write!(f, "janext"),
            Template::Janudocs(None) => write!(f, "janudocs"),
            Template::Janudocs(Some(sub_template)) => write!(f, "janudocs-{sub_template}"),
        }
    }
}

impl FromStr for Template {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "janext" => Ok(Template::Janext),
            "janudocs" => Ok(Template::Janudocs(None)),
            _ => Err(format!(
                "{YELLOW}{s}{RESET} is not a valid template. Valid templates are [{}]",
                Template::ALL_TOP_LEVEL
                    .iter()
                    .map(|e| format!("{GREEN}{e}{RESET}"))
                    .collect::<Vec<_>>()
                    .join(", ")
            )),
        }
    }
}

impl Displayable for Template {
    fn display_text(&self) -> &'static str {
        match self {
            Template::Janext => "\x1b[33mJanext - (https://www.janext.netlify.app/)\x1b[0m",
            Template::Janudocs(None) => {
                "\x1b[38;2;255;215;0mJanudocs - (https://www.janudocs.netlify.app/)\x1b[0m"
            }
            Template::Janudocs(Some(sub_template)) => match sub_template {
                JanudocsSubTemplate::React => "\x1b[38;2;255;215;0mJanudocs with React\x1b[0m",
                JanudocsSubTemplate::Solid => "\x1b[38;2;255;215;0mJanudocs with Solid\x1b[0m",
            },
        }
    }
}

impl<'a> Template {
    pub(crate) const ALL_TOP_LEVEL: &'a [Template] = &[Template::Janext, Template::Janudocs(None)];

    fn transform_to_pascal_case(s: String) -> String {
        let mut result = String::new();
        let mut capitalize_next = false;
        for (s, c) in s.chars().enumerate() {
            if s == 0 {
                result.push(c.to_ascii_uppercase());
            } else if capitalize_next {
                result.push(c.to_ascii_uppercase());
                capitalize_next = false;
            } else if ['_', '-'].contains(&c) {
                capitalize_next = true;
            } else {
                result.push(c);
            }
        }
        result
    }

    pub(crate) fn render(
        &self,
        target_dir: &path::Path,
        _pkg_manager: PackageManager,
        project_name: &str,
        package_name: &str,
    ) -> anyhow::Result<()> {
        let lib_name = format!("{}_lib", package_name.replace('-', "_"));
        let project_name_pascal_case = Self::transform_to_pascal_case(project_name.to_string());

        let template_data: HashMap<&str, String> = [
            ("project_name", project_name.to_string()),
            (
                "project_name_pascal_case",
                project_name_pascal_case.to_string(),
            ),
            ("package_name", package_name.to_string()),
            ("lib_name", lib_name),
        ]
        .into();

        let write_file = |file: &str,
                          template_data: HashMap<&str, String>,
                          skip_count: usize|
         -> anyhow::Result<()> {
            // remove the first component, which is certainly the template directory they were in before getting embeded into the binary
            let p = path::PathBuf::from(file)
                .components()
                .skip(skip_count)
                .collect::<Vec<_>>()
                .iter()
                .collect::<path::PathBuf>();

            let p = target_dir.join(p);
            let file_name = p.file_name().unwrap().to_string_lossy();

            let file_name = match &*file_name {
                "gitignore" => ".gitignore",
                // skip manifest
                name if name.starts_with("%(") && name[1..].contains(")%") => {
                    let mut s = name.strip_prefix("%(").unwrap().split(")%");
                    let (mut _flags, _name) = (
                        s.next().unwrap().split('-').collect::<Vec<_>>(),
                        s.next().unwrap(),
                    );

                    // skip writing this file
                    return Ok(());
                }
                name => name,
            };

            let (file_data, file_name) = if let Some(new_name) = file_name.strip_suffix(".lte") {
                let data = lte::render(
                    EMBEDDED_TEMPLATES::get(file).unwrap().data.to_vec(),
                    &template_data,
                )?
                .replace("<JANUSTACK-TEMPLATE-NAME>", project_name);
                (data.into_bytes(), new_name)
            } else {
                let plain_data = EMBEDDED_TEMPLATES::get(file).unwrap().data.to_vec();
                let data = String::from_utf8(plain_data.clone())
                    .map(|s| {
                        s.replace("<JANUSTACK-TEMPLATE-NAME>", &project_name)
                            .into_bytes()
                    })
                    .unwrap_or(plain_data);
                (data, file_name)
            };

            let file_name = lte::render(file_name, &template_data)?;

            let parent = p.parent().unwrap();
            fs::create_dir_all(parent)?;
            fs::write(parent.join(file_name), file_data)?;
            Ok(())
        };

        let current_template_name = match self {
            Template::Janudocs(None) => "janudocs".to_string(),
            Template::Janudocs(Some(sub_template)) => {
                format!("janudocs/{}", sub_template.to_simple_string())
            }
            _ => self.to_string(),
        };

        let skip_count = current_template_name.matches('/').count() + 1;
        for file in EMBEDDED_TEMPLATES::iter().filter(|e| {
            let path = path::PathBuf::from(e.to_string());
            let _components: Vec<_> = path.components().collect();
            let path_str = path.to_string_lossy();
            // let template_name = components.first().unwrap().as_os_str().to_str().unwrap();
            path_str.starts_with(&current_template_name)
        }) {
            write_file(&file, template_data.clone(), skip_count)?;
        }

        handle_brand_text("\nProject template successfully scaffolded!\n");
        Ok(())
    }
}

fn fmt_sub_template<T>(template: &T, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result
where
    T: Copy + PartialEq + Eq + 'static,
{
    let type_id = TypeId::of::<T>();

    if type_id == TypeId::of::<JanudocsSubTemplate>() {
        let janudocs_template: &JanudocsSubTemplate = unsafe { transmute(template) };
        match janudocs_template {
            &JanudocsSubTemplate::React => write!(f, "\x1b[36mReact\x1b[0m"),
            &JanudocsSubTemplate::Solid => write!(f, "\x1b[38;2;68;206;246mSolid\x1b[0m"),
        }
    } else {
        Err(std::fmt::Error)
    }
}
