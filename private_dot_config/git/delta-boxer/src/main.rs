use regex::Regex;
use std::io::{self, BufRead};
use std::process::{Command, Stdio};

fn main() -> io::Result<()> {
    let mut delta = Command::new("delta")
        .args(std::env::args().skip(1))
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()?;

    let mut stdin = delta.stdin.take().unwrap();
    std::thread::spawn(move || {
        io::copy(&mut io::stdin(), &mut stdin).ok();
    });

    let stdout = delta.stdout.take().unwrap();
    let reader = io::BufReader::new(stdout);

    let moved_re = Regex::new(r"\x1b\[48;2;45;32;47").unwrap();

    let mut in_moved_block = false;
    let mut moved_block = Vec::new();

    for line in reader.lines() {
        let line = line?;
        let is_moved = moved_re.is_match(&line);

        if is_moved {
            if !in_moved_block {
                in_moved_block = true;
                moved_block.clear();
            }
            moved_block.push(line);
        } else {
            if in_moved_block {
                print_boxed_block(&moved_block);
                moved_block.clear();
                in_moved_block = false;
            }
            println!("{}", line);
        }
    }

    if in_moved_block {
        print_boxed_block(&moved_block);
    }

    delta.wait()?;
    Ok(())
}

fn print_boxed_block(lines: &[String]) {
    if lines.is_empty() {
        return;
    }

    let max_visible_len = lines
        .iter()
        .map(|l| strip_ansi(l).len())
        .max()
        .unwrap_or(0);

    println!("┌{}┐", "─".repeat(max_visible_len + 2));

    for line in lines {
        let visible_len = strip_ansi(line).len();
        let padding = " ".repeat(max_visible_len - visible_len);
        println!("│ {}{} │", line, padding);
    }

    println!("└{}┘", "─".repeat(max_visible_len + 2));
}

fn strip_ansi(s: &str) -> String {
    let re = Regex::new(r"\x1b\[[0-9;]*m").unwrap();
    re.replace_all(s, "").to_string()
}
