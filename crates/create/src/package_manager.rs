use std::{fmt::Display, str::FromStr};

use crate::{template::Template, utils::colors::*};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[non_exhaustive]
pub enum PackageManager {
    Bun,
    Deno,
    Npm,
    Pnpm,
}

impl Default for PackageManager {
    fn default() -> Self {
        PackageManager::Bun
    }
}

impl Display for PackageManager {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            PackageManager::Bun => write!(f, "bun"),
            PackageManager::Deno => write!(f, "deno"),
            PackageManager::Npm => write!(f, "npm"),
            PackageManager::Pnpm => write!(f, "pnpm"),
        }
    }
}

impl FromStr for PackageManager {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "bun" => Ok(PackageManager::Bun),
            "deno" => Ok(PackageManager::Deno),
            "npm" => Ok(PackageManager::Npm),
            "pnpm" => Ok(PackageManager::Pnpm),
            _ => Err(format!(
                "{YELLOW}{s}{RESET} is not a valid package manager. Valid package mangers are [{}]",
                PackageManager::ALL
                    .iter()
                    .map(|e| format!("{GREEN}{e}{RESET}"))
                    .collect::<Vec<_>>()
                    .join(", ")
            )),
        }
    }
}

impl<'a> PackageManager {
    pub const ALL: &'a [PackageManager] = &[
        PackageManager::Bun,
        PackageManager::Deno,
        PackageManager::Npm,
        PackageManager::Pnpm,
    ];
}

impl PackageManager {
    /// Returns templates without flavors
    pub const fn templates_no_flavors(&self) -> &[Template] {
        match self {
            PackageManager::Bun
            | PackageManager::Deno
            | PackageManager::Npm
            | PackageManager::Pnpm => &[Template::Janext, Template::Janudocs(None)],
        }
    }

    pub const fn install_cmd(&self) -> Option<&str> {
        match self {
            PackageManager::Bun => Some("bun install"),
            PackageManager::Deno => Some("deno install"),
            PackageManager::Npm => Some("npm install"),
            PackageManager::Pnpm => Some("pnpm install"),
        }
    }

    pub const fn default_cmd(&self) -> &'static str {
        match self {
            PackageManager::Bun => "bun dev",
            PackageManager::Deno => "deno task",
            PackageManager::Npm => "npm run dev",
            PackageManager::Pnpm => "pnpm dev",
        }
    }

    pub const fn update_cmd(&self) -> &'static str {
        match self {
            PackageManager::Bun => "bunx",
            PackageManager::Deno => "deno",
            PackageManager::Npm => "npx",
            PackageManager::Pnpm => "pnpm",
        }
    }
}
