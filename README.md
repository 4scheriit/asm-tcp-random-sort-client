# ITSC204 Final Project - TCP Client in x86-64 Assembly

## Overview

This repository contains our group final project for ITSC204 Computer Architecture.

The project is a TCP client written in x86-64 Assembly. The client will connect to a local TCP server, request random bytes, write the random data to an output file, sort the data using selection sort, and then write the sorted data to the same file.

## Team Members

- Maxwell Brown
- Filippo Cocco
- Daniel Paetkau

## Initial Module Split

- **Maxwell Brown** - Networking module
- **Daniel Paetkau** - File output module
- **Filippo Cocco** - Selection sort module

## Project Structure

```text
.
├── README.md
├── .gitignore
├── src/
│   ├── client.nasm
│   ├── networking.nasm
│   ├── fileio.nasm
│   └── sorting.nasm
└── docs/
    ├── architecture-overview.md
    └── team-contributions.md
```
