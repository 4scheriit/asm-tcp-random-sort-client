ITSC204 Final Project - TCP Client in x86-64 Assembly
=====================================================

Overview
--------

This repository contains our final group project for **ITSC204 Computer Architecture**.

The project is a **TCP client written entirely in x86-64 Assembly**. The client connects to the provided TCP server running on localhost, generates a **random valid 3-digit hexadecimal request** between `0x100` and `0x5FF`, sends that request to the server, receives that many random bytes, writes the original data to `output.txt`, sorts the same data using **selection sort**, and then appends the sorted result to the same file.

This final version is built around:

-   socket-based communication using Linux syscalls
-   dynamic random request generation on each run
-   heap-based storage for received bytes
-   clearly marked random and sorted sections in the output file
-   modular procedure-based design across multiple assembly files

* * * * *

Team Members
------------

-   **Maxwell Brown**
-   **Filippo Cocco**
-   **Daniel Paetkau**

* * * * *

Project Structure
-----------------

.\
├── README.md\
├── .gitignore\
├── client.nasm\
├── networking.nasm\
├── fileio.nasm\
├── sorting.nasm\
├── server_lh_8080.nasm\
├── architecture-overview.md\
└── team-contributions.md

* * * * *

What the Program Does
---------------------

Each time the client runs, it follows this flow:

1.  Generates a random valid request size between `0x100` and `0x5FF`
2.  Converts that value into a 3-digit uppercase hex request string
3.  Prints the request to the console
4.  Allocates heap space for the incoming data
5.  Creates a TCP socket
6.  Connects to the local server at `127.0.0.1:8080`
7.  Discards the server's startup prompt text
8.  Sends the generated request string to the server
9.  Receives exactly the requested number of random bytes
10. Creates `output.txt`
11. Writes the original random bytes under a marked header
12. Sorts the received bytes in memory using selection sort
13. Verifies that the buffer is actually sorted
14. Writes the sorted bytes under a second marked header
15. Closes the file, closes the socket, frees the heap buffer, and exits

* * * * *

Dynamic Request Generation
--------------------------

Unlike the earlier project stage, the client **does not use a fixed request like `2FF` anymore**.

Instead, on each run it:

-   uses the Linux `getrandom` syscall
-   generates a value in the valid range from `0x100` to `0x5FF`
-   stores that numeric value in `requested_bytes`
-   builds the matching 3-digit uppercase hex request string
-   sends that generated value to the server

That means the requested byte count changes from run to run while still staying inside the assignment's allowed range.

* * * * *

Module Breakdown
----------------

### `client.nasm`

This is the main control file for the program.

It is responsible for:

-   running the overall program flow
-   generating and displaying the request value
-   calling the networking procedures
-   calling the file output procedures
-   calling the sorting procedure
-   handling cleanup and exit paths

### `networking.nasm`

This module handles request setup, heap buffer management, and socket communication.

It is responsible for:

-   generating the random request size
-   storing the request as both text and numeric byte count
-   allocating heap space with `brk`
-   releasing that heap space after execution
-   creating the TCP socket
-   connecting to the localhost server
-   discarding the server's startup prompt
-   sending the request string
-   receiving the random bytes into the heap buffer

### `fileio.nasm`

This module handles output file creation and writing.

It is responsible for:

-   creating or truncating `output.txt`
-   writing the random data section header and bytes
-   writing the sorted data section header and bytes
-   appending newline separators
-   closing the output file cleanly

### `sorting.nasm`

This module handles the sorting logic.

It is responsible for:

-   sorting the received bytes using selection sort
-   verifying that the final buffer is in ascending order
-   returning status codes for success or failure cases

### `server_lh_8080.nasm`

This is the provided server file used for testing.

It is responsible for:

-   running the local TCP server
-   sending its startup prompt
-   accepting the client's request
-   generating random bytes
-   sending the requested number of bytes back to the client

* * * * *

Data Flow
---------

client.nasm\
  -> initialize random request\
  -> allocate receive buffer\
  -> networking.nasm\
  -> discard server prompt\
  -> send request\
  -> receive random bytes into heap buffer\
  -> fileio.nasm writes random data\
  -> sorting.nasm sorts and verifies buffer\
  -> fileio.nasm writes sorted data\
  -> output.txt

* * * * *

Output File Format
------------------

The program writes to `output.txt` using two clearly marked sections:

----- BEGINNING OF RANDOM DATA -----\
[random bytes written here]

----- BEGINNING OF SORTED DATA -----\
[sorted bytes written here]

This matches the assignment requirement to clearly separate the original random data from the sorted data.

* * * * *

Key Technical Details
---------------------

-   Written fully in **x86-64 Assembly**
-   Uses **Linux syscalls** directly
-   Uses **TCP sockets**
-   Connects to **127.0.0.1:8080**
-   Generates a **random valid request size** each run
-   Uses **heap memory via `brk`** for the receive buffer
-   Uses the **stack** for procedure calls and saved registers
-   Uses **selection sort** to sort the received bytes
-   Includes a **verification pass** after sorting
-   Uses separate procedures and modules for cleaner design
-   Includes comments throughout the code for readability

* * * * *

Heap and Stack Use
------------------

This project uses both heap/data memory and stack-based procedure logic.

### Heap Use

The receive buffer is allocated dynamically using the Linux `brk` syscall.\
That buffer holds:

-   the original random bytes from the server
-   the in-place sorted version of the same data

### Stack Use

The stack is used for:

-   procedure calls
-   saved registers
-   temporary saved arguments during file writes
-   general control flow and cleanup

This matches the project requirement to use both memory areas in the program design.

* * * * *

Selection Sort
--------------

The sorting module uses **selection sort** on the received byte buffer.

High-level logic:

1.  Start at the first byte
2.  Find the smallest byte in the remaining unsorted portion
3.  Swap it into the current position
4.  Move one position to the right
5.  Repeat until the buffer is sorted

After sorting, the program calls `verify_sorted` to confirm that the bytes are actually in ascending order.

* * * * *

Build and Run
-------------

### Assemble and link the server

nasm -f elf64 server_lh_8080.nasm -o server_lh_8080.o\
ld server_lh_8080.o -o server

### Assemble and link the client

nasm -f elf64 client.nasm -o client.o\
nasm -f elf64 networking.nasm -o networking.o\
nasm -f elf64 fileio.nasm -o fileio.o\
nasm -f elf64 sorting.nasm -o sorting.o\
ld client.o networking.o fileio.o sorting.o -o client

### Run the program

Start the server in one terminal:

./server

Run the client in another terminal:

./client

After execution, open:

output.txt

* * * * *

Example Runtime Behavior
------------------------

On a successful run, the client will:

-   print the generated request value to the console
-   connect to the local server
-   receive exactly that many random bytes
-   create `output.txt`
-   write the unsorted data to the file
-   sort and verify the data in memory
-   append the sorted data to the file
-   exit cleanly

Because the request is randomly generated each time, the exact requested byte count will vary from run to run.

* * * * *

Design Notes
------------

This project was organized into separate modules to make the code easier to:

-   divide across team members
-   test and debug
-   explain during the presentation
-   maintain as the project changed

Instead of placing everything in one file, the project separates:

-   main control flow
-   request generation and networking
-   file output
-   sorting and verification

This keeps the code more readable and closer to a clean procedure-based design.

* * * * *

Project Requirements Covered
----------------------------

This final project addresses the required course goals by:

-   implementing a TCP client in x86-64 Assembly
-   using socket syscalls with no external libraries
-   connecting to a locally running server
-   generating and sending a valid 3-digit hexadecimal request
-   requesting between `0x100` and `0x5FF` random bytes
-   receiving and storing the returned bytes
-   writing the original data to an output file
-   sorting the data using the assigned sorting algorithm
-   appending the sorted result to the same output file
-   using procedures and standard modular structure
-   using both heap/data memory and stack-based function flow
-   including sufficient code comments

* * * * *

Repository Purpose
------------------

This repository serves as:

-   the final submission for the ITSC204 Computer Architecture project
-   a record of the group's implementation and structure
-   a reference for how the final client was designed and built

* * * * *

Final Summary
-------------

This project is a modular TCP client in **x86-64 Assembly** that demonstrates:

-   low-level socket communication
-   random request generation with `getrandom`
-   dynamic heap allocation with `brk`
-   file output formatting
-   selection sort and verification
-   structured procedure-based design

The final result is a working client that generates a valid random request, receives that many random bytes from the local server, writes both the original and sorted data to `output.txt`, and showcases the core computer architecture concepts covered in the course.
