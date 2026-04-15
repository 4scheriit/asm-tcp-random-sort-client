ITSC204 Final Project - TCP Client in x86-64 Assembly
=====================================================

Overview
--------

This repository contains our group final project for **ITSC204 Computer Architecture**.

The goal of the project is to build a **TCP client fully in x86-64 Assembly** that connects to a locally running server, requests random bytes, stores the received data in an output file, sorts the data, and then writes the sorted version to the same file.

At this stage of the project, the core client flow has been laid out and the **networking** and **file output** portions have been implemented in structure. The **sorting module is still a placeholder** and will be completed in a later stage.

Team Members
------------

*   **Maxwell Brown**
    
*   **Filippo Cocco**
    
*   **Daniel Paetkau**
    

Current Module Split
--------------------

*   **Maxwell Brown** - Networking module
    
*   **Daniel Paetkau** - File input/output module
    
*   **Filippo Cocco** - Selection sort / algorithm module
    

Current Project Status
----------------------

### Implemented so far

*   Main client program flow in client.nasm
    
*   Socket creation in networking.nasm
    
*   TCP connection to localhost server in networking.nasm
    
*   Request sending to the server in networking.nasm
    
*   Receive loop for collecting incoming bytes in networking.nasm
    
*   Output file creation in fileio.nasm
    
*   Writing a clearly marked **random data** section to the file
    
*   Writing a clearly marked **sorted data** section to the file
    
*   Output file closing procedure
    

### Still in progress

*   Full selection sort implementation in sorting.nasm
    
*   Full end-to-end testing of all modules together
    
*   Final cleanup, validation, and polishing
    
*   Documentation updates in docs/
    

How the Program Is Designed
---------------------------

The project is split into separate assembly modules so each major responsibility is kept isolated and easier to manage.

### client.nasm

This is the main control file for the program.

It currently:

1.  Creates the client socket
    
2.  Connects to the local TCP server
    
3.  Sends a request for random bytes
    
4.  Receives the returned bytes into a shared buffer
    
5.  Creates the output file
    
6.  Writes the random data section
    
7.  Calls the sorting procedure
    
8.  Writes the sorted data section
    
9.  Closes the file and exits
    

### networking.nasm

This module handles all networking-related procedures.

Current procedures:

*   create\_socket
    
*   connect\_to\_server
    
*   send\_request
    
*   receive\_data
    

Current behavior:

*   Uses Linux syscalls directly
    
*   Connects to **127.0.0.1:8080**
    
*   Sends the request string "2FF"
    
*   Uses a receive loop to keep reading until the requested amount of data has been collected or reading stops
    

### fileio.nasm

This module handles file creation and writing.

Current procedures:

*   create\_output\_file
    
*   write\_random\_section
    
*   write\_sorted\_section
    
*   close\_output\_file
    

Current behavior:

*   Creates output.txt
    
*   Writes a visible header before each data section
    
*   Appends a newline after each section
    
*   Checks for failed or incomplete writes
    

### sorting.nasm

This module is reserved for the sorting algorithm.

Current state:

*   Structure exists
    
*   selection\_sort symbol is exported
    
*   Full sorting logic still needs to be implemented
    

Current Data Flow
-----------------

`   Server -> networking.nasm -> recv_buffer -> fileio.nasm -> sorting.nasm -> fileio.nasm -> output.txt   `

### In plain words

*   The client asks the server for random bytes
    
*   The server sends the bytes back
    
*   The client stores those bytes in recv\_buffer
    
*   The raw bytes are written to the output file
    
*   The buffer is then sorted
    
*   The sorted bytes are written to the file after the original section
    

Current Request Format
----------------------

Right now, the networking module sends:

`   2FF   `

This represents a request for:

`   0x2FF = 767 bytes   `

So the client is currently built around requesting and receiving **767 bytes** from the server.

Output File Format
------------------

The client writes data into output.txt using clearly marked sections.

Current headers:

`   ----- BEGINNING OF RANDOM DATA -----  ----- BEGINNING OF SORTED DATA -----   `

This keeps the file output readable and matches the project requirement of clearly separating the two sections.

Project Structure
-----------------

```text
.
├── README.md
├── .gitignore
├── src/
│   ├── client.nasm
│   ├── networking.nasm
│   ├── fileio.nasm
│   ├── sorting.nasm
│   └── server_lh_8080.nasm
└── docs/
    ├── architecture-overview.md
    └── team-contributions.md
```

> Note: the repository is currently organized with the .nasm files at the root level.

Key Technical Notes
-------------------

*   Written in **x86-64 Assembly**
    
*   Uses **Linux syscalls**
    
*   Uses **TCP sockets**
    
*   Connects to a **local server**
    
*   Uses a shared receive buffer for incoming data
    
*   Follows a modular design with separate procedures for each responsibility
    
*   Includes comments intended to keep the code readable for beginners
  

## Build and Run Notes

Exact build commands may change depending on the final testing environment, but the intended workflow is:

1. Assemble the server
2. Assemble the client modules
3. Link the client
4. Run the server
5. Run the client
6. Check `output.txt`

Example Linux-style flow:

```bash
nasm -f elf64 server_lh_8080.nasm -o server_lh_8080.o
ld server_lh_8080.o -o server

nasm -f elf64 client.nasm -o client.o
nasm -f elf64 networking.nasm -o networking.o
nasm -f elf64 fileio.nasm -o fileio.o
nasm -f elf64 sorting.nasm -o sorting.o
ld client.o networking.o fileio.o sorting.o -o client
```

Then run in separate terminals:

```bash
./server
./client
```

What This Stage Shows
---------------------

This stage of the project demonstrates that the program structure is in place and that the client is being built around the required flow:

*   connect
    
*   request data
    
*   receive data
    
*   write raw data
    
*   sort data
    
*   write sorted data
    

The biggest remaining code task is completing the sorting logic and then performing full integration testing.

Next Steps
----------

*   Implement selection\_sort in sorting.nasm
    
*   Verify the returned data is correctly sorted before writing
    
*   Perform full testing with the provided server
    
*   Confirm output formatting and byte counts
    
*   Expand the documentation in architecture-overview.md
    
*   Track completed work more fully in team-contributions.md
    

Repository Purpose
------------------

This repository is both:

*   a course final project submission
    
*   a record of how the project was structured and built as a team
    

As development continues, this README will be updated to reflect the final working state of the client.
