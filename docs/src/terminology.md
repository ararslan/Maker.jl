
#### Terminology

- **action** -- The method to be executed when a task is run.

- **dependency** -- Tasks may have dependencies. If task "A" has dependencies
  "B" and "C", `make("A")` will check "B" and "C" before executing "A". 
  Dependencies are stored by name, so task "B" can be defined after task "A".
  Circular dependencies are not currently checked.

- **prerequisite** -- Another name for **dependency**.

- **target** -- Another name for a **task**.

- **task** -- The basic unit of work. A task is an AbstractTarget. The
  following AbstractTargets are provided:
  
| Registration method | AbstractTarget    |
|:--------------------|:------------------|
| `Maker.directory`   | `DirectoryTarget` |
| `Maker.directory`   | `DirectoryTarget` |
| `Maker.file`        | `FileTarget`      |
| `Maker.phony`       | `PhonyTarget`     |
| `Maker.task`        | `GenericTarget`   |
| `Maker.variable`    | `VariableTarget`  |
