module config

import os
import json2

pub struct Config {
pub:
	database        string
	pool_size       i32
	port            u16 @[required]
	report_interval u32
	walk            []WalkConfig
}

pub struct WalkConfig {
pub:
	root     string
	override ?string
	exclude  []string
}

pub fn parse(config_path string) !Config {
	content := os.read_file(config_path)!
	cfg := json2.decode[Config](content, strict: true)!
	return cfg
}

pub fn (cfg &Config) override_root(path string) ?string {
	for wc in cfg.walk {
		override := wc.override or {
			continue
		}
		if path.starts_with(wc.root) {
			return path.replace_once(wc.root, override)
		}
	}
	return none
}
