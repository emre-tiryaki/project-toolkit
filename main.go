package main

import (
	"errors"
	"fmt"
	"os"
)

func main() {
	cfg = loadConfig()

	if len(os.Args) < 2 {
		cmdHelp()
		os.Exit(0)
	}

	command := os.Args[1]
	args := os.Args[2:]

	if command != "help" && command != "clone" && command != "config" {
		if err := ensureWorkspace(); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	}

	var err error
	switch command {
	case "new":
		err = cmdNew(args)
	case "open":
		err = cmdOpen(args)
	case "rm":
		err = cmdRm(args)
	case "list", "ls":
		err = cmdList(args)
	case "find":
		err = cmdFind(args)
	case "rename":
		err = cmdRename(args)
	case "clone":
		err = cmdClone(args)
	case "config":
		err = cmdConfig(args)
	case "help", "-h", "--help":
		cmdHelp()
	case "version", "--version":
		fmt.Println("project-toolkit 1.0.0")
	default:
		err = errors.New(getMsg(msgErrInvalidCommand, command))
	}

	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
