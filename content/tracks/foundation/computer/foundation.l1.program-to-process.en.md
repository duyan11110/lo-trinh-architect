---
id: foundation.l1.program-to-process
lang: en
track: foundation
level: 1
stage: 0
module: computer
main_path: true
title: "From a compiled file to a running process"
duration_min: 10
skills: [foundation.os.process]
prereqs: []
related: [foundation.l1.ip-and-ports]
vocab: [process]
example_tag: stage-0
versions_used: [dotnet, docker, shell, procps]
content_version: 1
status: approved
approved_by: auto
reviewed_at: "2026-09-28T14:00:00+07:00"
---

## Before you start

- No prerequisites — start here.

## The situation

You run `scripts/up.sh` on Đơn Hàng, the small ordering system this course is built around, for the first time. It prints its progress and the site's address, finishes, and hands the terminal back to you. Nothing else is on screen: no window of its own, no further output. You open that address in a browser anyway and the site answers, and it still answers ten minutes later while you make coffee.

You never left anything visibly running, and your terminal is free. Something on this machine is still there, waiting for your browser and answering it. What keeps running after the command that started it has finished?

## Core concepts

- program — a file on disk holding instructions. It does nothing at all until something starts it.
- **process** — one run of a program. The operating system is the program that starts other programs, gives them memory and keeps track of them. It gives each run its own memory, at least one flow of execution through the instructions — the step-by-step following of them; a run can have more than one, which a later lesson covers — and a number that names it while it lasts. A running process can also make a copy of itself, which is a process too.
- process id — the number the operating system assigns to a process. It identifies that run while the run is alive, and the system may hand the same number to a later run.
- exit code — the one number a finished run leaves behind for whoever started it. The convention is `0` for success and anything else for failure, though a run stopped from outside can leave a nonzero number without having failed.

## How it works

```mermaid
flowchart LR
  F["File on disk"] -->|you start it| OS["Operating system"]
  OS --> P["Process: own memory, a flow, an id"]
  P --> R["Ends by itself"]
  P --> C["Crash"]
  P --> K["Stopped from outside"]
  R --> X["Exit code, to whoever started it"]
  C --> X
  K --> X
```

In the situation above, `scripts/up.sh` is a file on disk, and a script counts as a program too; nothing about it moves until you run it. Running it asks the operating system to build a process around it: memory only that run can reach, at least one flow of execution, and an id that names the run while it lasts.

Start the same file a second time and you get a second process, with memory of its own and a second id. Neither can reach what the other holds unless it asks the operating system for something built for sharing.

A process can outlive the command that started it. `scripts/up.sh` asked for several long-lived processes, waited only until they were up, not until they ended, then finished. They stayed, and one of them is what answers your browser. The site is one such long-lived process, and so is the part of Đơn Hàng you will build later.

A run usually ends in one of three ways: it ends by itself, it crashes, or something outside it stops it. Ending by itself means its main function returns, or it asks to end; crashing means it hits an error it does not handle and is ended because of it.

Whoever started it gets one number back. For a run that ends by itself, the number is its own answer, `0` for success and anything else for failure. After a crash, the number is not one the program chose. When something outside stops a run, the run may be told first and choose its own number. `sleep`, below, does not react, so the number it leaves is not its own.

## In the Đơn Hàng system

The console sample under `samples/DonHang.Samples/` asks the operating system about its own run and prints what it learns.

```csharp file=samples/DonHang.Samples/Samples/Computer/HelloProcess.cs tag=stage-0 lines=8-13
        var process = System.Diagnostics.Process.GetCurrentProcess();

        Console.WriteLine($"process id: {process.Id}");
        Console.WriteLine($"started from: {Environment.ProcessPath}");
        Console.WriteLine($"working directory: {Environment.CurrentDirectory}");
        Console.WriteLine("this process ends when Main returns, and reports 0");
```

The first line asks the operating system for the run the program is in; the next three print things about that one run, and the last one states in words how the run will end — `Main` returns, and the run reports `0`. `process.Id` is the number the operating system assigned to this run; a tool that lists the runs on the same machine, like `ps` in the script below does inside the example system, lists each run by that kind of number. `Environment.ProcessPath` is the file that was started — the same one on every run started the same way, while the id changes. `Environment.CurrentDirectory` is the folder this run works in, which a later lesson takes up.

The script under `scripts/computer/` makes the same points with two copies of one program. This script does not run directly on your computer; you start it from your terminal, and it runs inside the example system that `scripts/up.sh` started, so that system has to be up first. `sleep` is a program that does nothing but stay alive for the number of seconds you give it, which is why two copies can still be listed a moment later. All of this exists to show one program alive twice, and three ending numbers: one the run did not choose, and two the script chose for itself.

```bash file=scripts/computer/list-processes.sh tag=stage-0 lines=7-21
sleep 30 &
first=$!
sleep 30 &
second=$!

echo "the same program started twice is two processes:"
ps -o pid=,args= -p "$first,$second" | sed 's/^ *//'

kill "$first" "$second"
wait "$first" 2>/dev/null || echo "the first one ended with exit code $?"
wait "$second" 2>/dev/null || true

echo
( exit 0 ) && echo "a program that succeeds exits with 0"
( exit 3 ) || echo "a program that fails exits with $?"
```

```text output=true
the same program started twice is two processes:
... sleep 30
... sleep 30
the first one ended with exit code 143

a program that succeeds exits with 0
a program that fails exits with 3
```

Two spellings matter here: `&` lets the script start a program and carry on without waiting, and `$!` right after it holds the id of the run just started, which is why both `sleep 30` runs are alive at the same time. Commands inside `( … )` run in a separate copy of the running script — a process of its own, not a new start of the file — which `exit 3` ends with the number 3. A running process can copy itself like this, and the copy is a process too, with its own id and ending number, though no file was started.

On the last two lines, `&&` runs the next command only if the number was `0`, and `||` only if it was not. The others — `ps`, `kill`, `wait`, `$?`, `sed`, `2>/dev/null`, `|| true` — belong to the terminal module: the `ps` line lists the two runs, the `kill` line stops them, and the first `wait` line prints the number the first one left.

Now the output. The two `sleep 30` lines are the same program listed twice under different ids; the output above shows them as `...` because the ids change on every run. Both copies are then stopped the same way, and the script reports an ending number for the first one only, to keep the output short. That copy did not choose `143` — it was stopped from outside, and `143` is what the script reports for that kind of stop inside the example system, where it always runs. The last two lines are not programs on disk at all: each is the script ending a copy of itself with a number it chose, `0` for success and `3` for failure.

## Beginners often think…

- **"Running my program twice makes the second run see the variables of the first."** → Actually each run is a separate process with its own memory, and starts from nothing. You notice this when you run a program twice to "keep the list from the first run" and the second one starts with an empty list.
- **"If the program prints nothing, it is not running."** → Actually printing and running are separate things: `scripts/up.sh` goes quiet and the site keeps answering for as long as you leave it. You notice this when you start a program a second time because the first showed nothing, and you now have two copies of the same program running.
- **"A program that ended without an error message ended fine."** → Actually the ending is reported as a number, and a program can print nothing and still leave a nonzero one. You notice this when one of your scripts calls another, the called one prints nothing at all, and the calling one carries on — the failure was only in the number nobody read.

## Try it (3 minutes)

1. Start the example system with `scripts/up.sh`; it finishes on its own and the system stays up, which step 2 needs.
2. In the same terminal, run `scripts/computer/list-processes.sh` twice in a row. As "In the Đơn Hàng system" said, the script runs inside the example system, so step 1 has to come first; the numbers below are the ones it reports there. Compare the two ids printed by the first run with the two printed by the second.

Expected result: each run lists the same program `sleep 30` twice under two different ids, and across the two runs you will almost certainly see four different numbers — one run of a program, one id. The three numbers after them are the same both times, as the example system runs it: `143` for the copy stopped from outside, then `0` and `3` for the two endings the script chose for itself.

## Connections

- [[foundation.l1.memory-stack-heap]] — one step deeper: it opens the "own memory" this lesson hands to each process and shows where your variables sit inside it.
- [[foundation.l1.ip-and-ports]] — the same running program seen from the network: how something outside the machine reaches one process among the many the machine is running.

## Five-line summary

1. A program is a file on disk; a process is one run of it, with its own memory, at least one flow, and an id.
2. Starting the same file twice gives two processes, and neither can see what the other holds unless it asks for sharing.
3. A process can outlive the command that started it, and it can run for as long as you leave it while printing nothing.
4. A run usually ends by itself, by crashing, or because something outside it stopped it.
5. Whoever started it reads one number, the exit code: `0` for success, anything else for failure, and a stop from outside can decide it instead.
