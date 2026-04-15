Architecture Overview
=====================

Purpose of the Project
----------------------

This project is a TCP client written fully in **x86-64 Assembly** for the ITSC204 Computer Architecture final project.

The client connects to a locally running TCP server, requests a chosen number of random bytes, receives those bytes, writes them to an output file, sorts the same data, and then writes the sorted version to the file as a second section.

High-Level Program Flow
-----------------------

The program is designed around a simple step-by-step flow:

1.  Start the client
    
2.  Create a TCP socket
    
3.  Connect to the local server
    
4.  Send a request for random bytes
    
5.  Receive the bytes from the server into memory
    
6.  Create or open the output file
    
7.  Write the random data section to the file
    
8.  Sort the data in memory
    
9.  Write the sorted data section to the file
    
10.  Close the file
    
11.  Exit the program
    

Module Responsibilities
-----------------------

The project is split into separate assembly files so each part of the program has a clear responsibility.

### client.nasm

This is the main control file.

It is responsible for:

*   calling the major procedures in the correct order
    
*   managing the overall flow of the program
    
*   passing shared data between modules
    
*   handling program exit
    

### networking.nasm

This file handles all socket and server communication logic.

It is responsible for:

*   creating the socket
    
*   connecting to the TCP server
    
*   sending the byte request
    
*   receiving data back from the server
    

### fileio.nasm

This file handles output file creation and writing.

It is responsible for:

*   creating the output file
    
*   writing the random data section
    
*   writing the sorted data section
    
*   closing the file when finished
    

### sorting.nasm

This file handles the sorting logic.

It is responsible for:

*   sorting the received random bytes in memory
    
*   keeping the sorting logic separate from networking and file writing
    

### server\_lh\_8080.nasm

This is the provided server used for testing.

It is responsible for:

*   listening for client connections
    
*   receiving the client's requested byte count
    
*   generating random data
    
*   sending the requested bytes back to the client
    

Current Data Flow
-----------------

```text
client.nasm
  -> networking.nasm
  -> receive buffer
  -> fileio.nasm
  -> sorting.nasm
  -> fileio.nasm
  -> output.txt
```

How the Modules Work Together
-----------------------------

The modules are designed to work as one pipeline.

*   The **main client** starts the process.
    
*   The **networking module** gets the data from the server.
    
*   The received data is stored in a shared memory buffer.
    
*   The **file I/O module** writes that original data to the file.
    
*   The **sorting module** sorts the same buffer in memory.
    
*   The **file I/O module** then writes the sorted version to the file.
    

This keeps each file focused on one job and makes the project easier to read, debug, and explain.

File Output Design
------------------

The output file is meant to clearly show both the original and sorted data.

The file contains two marked sections:

`   ----- BEGINNING OF RANDOM DATA -----  [random bytes written here]  ----- BEGINNING OF SORTED DATA -----  [sorted bytes written here]   `

This matches the project requirement to clearly separate the two parts of the output.

Networking Design
-----------------

The client uses Linux TCP socket syscalls directly in Assembly.

At the current stage, the client:

*   connects to 127.0.0.1
    
*   uses port 8080
    
*   sends the request string 2FF
    

This means the client is currently requesting:

`   0x2FF = 767 bytes   `

The receive logic is designed as a loop so it can continue reading until all requested bytes have arrived or the server stops sending data.

Memory Use
----------

The project uses memory in a few important ways:

### Stack

The stack is used for:

*   procedure calls
    
*   saved registers
    
*   temporary local values
    

### Heap or Buffer Storage

The received server data must be stored in memory before it can be written and sorted.

That buffer is used for:

*   holding the original random bytes
    
*   giving the sorting procedure data to sort
    
*   giving the file writing procedure data to output
    

This follows the project requirement that the program use both **stack** and **heap/data memory** as part of its design.

Procedure-Based Design
----------------------

The project is built around separate procedures instead of one giant block of code.

Examples include:

*   create\_socket
    
*   connect\_to\_server
    
*   send\_request
    
*   receive\_data
    
*   create\_output\_file
    
*   write\_random\_section
    
*   write\_sorted\_section
    
*   close\_output\_file
    
*   selection\_sort
    

This makes the code:

*   easier to test
    
*   easier to explain in the presentation
    
*   easier to divide between group members
    
*   more aligned with standard calling-convention-based design
    

Why the Project Was Structured This Way
---------------------------------------

The project was divided into modules for practical reasons:

*   better teamwork
    
*   easier debugging
    
*   cleaner code organization
    
*   clearer presentation structure
    
*   easier tracking of individual contributions
    

Instead of mixing networking, file writing, and sorting in one file, each major responsibility has its own place.

Current State of the Architecture
---------------------------------

At this point in the project:

*   the general program structure is in place
    
*   the networking flow has been built
    
*   the file writing flow has been built
    
*   the sorting module structure exists
    
*   full integration and final testing are still ongoing
    

So the architecture is already laid out, even if some parts are still being finished.

Planned Final Result
--------------------

When complete, the full system will do the following in one run:

1.  Connect to the provided local TCP server
    
2.  Request a valid number of random bytes
    
3.  Receive and store those bytes
    
4.  Write the unsorted bytes to output.txt
    
5.  Sort the bytes using the assigned sorting algorithm
    
6.  Append the sorted bytes to output.txt
    
7.  Exit cleanly
    

Summary
-------

This project is a modular x86-64 Assembly TCP client built around four main concerns:

*   program control
    
*   networking
    
*   file output
    
*   sorting

Its architecture is designed to keep those concerns separate while allowing them to work together in one complete flow from server request to final sorted output file.
