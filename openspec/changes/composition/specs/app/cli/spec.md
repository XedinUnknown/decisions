# Spec Delta

## Purpose

Defines the command-line provider: a generic command surface that it and other providers add commands to, so that adding a command never changes the command line.

## ADDED Requirements

### Requirement: Commands come from composition
The command line SHALL run the command named by its first argument, looked up among the commands contributed through composition, passing it the remaining arguments. The command-line provider SHALL contribute no command other than `help`.

#### Scenario: Contributed command runs
- **WHEN** a provider contributes a command `echo` that prints its arguments, and the command line is run as `decisions echo a b`
- **THEN** it prints `a b` and exits with status 0

#### Scenario: Command replaced by a later provider
- **WHEN** a later provider contributes a different `echo` command
- **THEN** the later command runs instead

### Requirement: Help lists contributed commands
Running the command line without arguments or with `help` SHALL list every contributed command with its one-line summary, in name order.

#### Scenario: Listing
- **WHEN** providers contribute `validate` and `echo` and the command line is run without arguments
- **THEN** the output lists `echo` and `validate` with their summaries, and the exit status is 0

### Requirement: Unknown commands reported
Running an unknown command SHALL print an error naming it, followed by the list of commands, and exit with a non-zero status.

#### Scenario: Typo
- **WHEN** the command line is run as `decisions valdate`
- **THEN** the output names `valdate` and lists the available commands, and the exit status is non-zero

### Requirement: Composition failures reported
When a command fails because a key is missing or a dependency cycle exists, the command line SHALL print that error, including the key or the cycle, and exit with a non-zero status, without a stack trace unless debugging output is requested.

#### Scenario: Missing key
- **WHEN** a command depends on a key that nothing supplies
- **THEN** the output contains the key, and the exit status is non-zero

### Requirement: Platform access through required keys
The command-line provider SHALL read its arguments and write its output and errors only through keys it requires and does not define (`cli/args`, `cli/output`, `cli/errors`), so that any platform provider, or a test, can bind them.

#### Scenario: In-memory platform
- **WHEN** a test composes the application provider with a test platform provider that binds arguments, file access and output to in-memory values, and runs a command that reads a file
- **THEN** the command reads the in-memory file and its output is captured, with no real file touched

#### Scenario: Unbound requirement
- **WHEN** the application provider is composed without any platform provider and `cli/main` is resolved
- **THEN** resolution fails with an error naming `cli/args`
