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
            Template::Janext => "\x1b[33mJanext https://www.janext.netlify.app/\x1b[0m",
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

        handle_brand_text("\n ✔️ Template copied Successfully! \n");
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
            &JanudocsSubTemplate::React => write!(f, "\x1b[36mReact - (https://react.dev/)\x1b[0m"),
            &JanudocsSubTemplate::Solid => write!(
                f,
                "\x1b[38;2;68;206;246mSolid - (https://solidjs.com/)\x1b[0m"
            ),
        }
    } else {
        Err(std::fmt::Error)
    }
}
