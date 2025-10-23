import serial

"""
 ==========================         UART Communication Manager          =========================== 

FPGA UART Interface Notes:
    1. fifo_size: Number of values that can be transmitted/received at once.
    2. FIFO_register:  Defines the maximum number of elements that can be sent or received at once.
                       Ensure it matches the FIFO depth of the FPGA, otherwise, data may be lost.
    3. byte_size: Defines number of bytes per data value (1-4 bytes).
                  Data is transmitted in big-endian format by default. 
    4. parallel_data: Number of values sent or received in parallel.

Serial Port Settings:
    - 'port': Set this according to your system (e.g., 'COM4' for Windows, '/dev/ttyUSB0' for Linux).
    - 'baudrate': Must match the FPGA UART configuration to avoid data corruption.
    - 'bytesize': Usually 8 bits, but ensure it aligns with the FPGA UART settings.
    - 'parity' and 'stopbits': Ensure they match the FPGA, otherwise communication issues will occur.

    5. vector FPGA_RX_vector: Give exact amount of int which declare the amount of FIFO_register otherwise compiler throw error

    7. Timeout: Set appropriately to avoid infinite blocking while reading data.
    8. Ensure data conversion (hex to bytes) is correctly formatted for FPGA compatibility.
    9. Close the serial connection at the end to avoid port locking issues.
=====================================================================================================
"""
fifo_size = 256              # Number of FIFO storage locations per parallel input stream. If fifo_size = 16, you can queue up 16 data items.
parallel_data_tx = 1        # Number of parallel data inputs being transmitted from PC to FPGA. e.g., 2 parallel streams (like two channels transmitting at once).
Byte_size_tx = 4            # Byte size per data element for transmission (1-4) 

Byte_size_rx = 4           # Byte size per data element for receiving (1-4) 
parallel_data_rx = 1        # Number of parallel outputs from FPGA to PC  

FIFO_Resigter = fifo_size * parallel_data_tx * Byte_size_tx
FIFO_equality_ratio = int((parallel_data_tx * Byte_size_tx) / (parallel_data_rx * Byte_size_rx))

# ========================    UART Serial Communication    ============================== #

ser = serial.Serial(
    port='COM10',          # Replace with your port (e.g., /dev/ttyUSB0 on Linux)
    baudrate=9600,        # Baud rate (match this with your FPGA configuration)
    bytesize=serial.EIGHTBITS,  # Data bits (8 based on your FPGA setup)
    parity=serial.PARITY_NONE,  # Parity (None, Even, Odd)
    stopbits=serial.STOPBITS_ONE,  # Stop bits (1 or 2)
    timeout= 3           # Timeout for read/write operations
)

# ========================    FPGA Input Vector Configuration    ========================== #
#fpga_tx_matrix  = [[55, 142, 56, 100]]


#fpga_tx_matrix  = [[287454020, 287454021, 287454022, 287454023, 287454024, 287454025, 287454026, 287454027,
#                    287454028, 287454029, 287454028, 287454030, 287454031, 287454032, 287454033, 287458800]]

fpga_tx_matrix = [[i for i in range(1, 513)]]

fpga_tx_matrix[0][0] = 2

def hex_to_bytes(hex_list):
    """Convert a list of hexadecimal numbers to bytes."""
    corrected_list = [num & 0xFF for num in hex_list]
    return bytes(corrected_list)

def vector_to_uart_bytes(FPGA_vector, Byte_size, endianness='big'):
    """
    Convert a 1D vector to UART-ready bytes with configurable byte size
    Args:
        FPGA_vector: 1D list of input values
        Byte_size: Number of bytes per value (1-4)
        endianness: 'big' (MSB first) or 'little' (LSB first)
    Returns:
        Byte stream ready for UART transmission
    """
    if not 1 <= Byte_size <= 4:
        raise ValueError("Byte_size must be between 1 and 4")
    
    max_val = (1 << (8 * Byte_size)) - 1
    byte_stream = []
    
    for num in FPGA_vector:
        if num < 0 or num > max_val:
            raise ValueError(f"Value {num} out of range for {Byte_size}-byte storage")
        
        for byte_num in range(Byte_size):
            shift = (Byte_size - 1 - byte_num) * 8 if endianness == 'big' else byte_num * 8
            byte = (num >> shift) & 0xFF
            byte_stream.append(byte)
    
    return bytes(byte_stream)

def uart_bytes_to_vector(byte_stream, Byte_size, endianness='big'):
    """Convert byte stream back to original vector"""
    if Byte_size not in {1, 2,3, 4}:
        raise ValueError("Byte_size must be 1, 2, or 4")
    
    vector = []
    for i in range(0, len(byte_stream), Byte_size):
        chunk = byte_stream[i:i+Byte_size]
        vector.append(int.from_bytes(chunk, endianness))
    
    return vector


vector_uart_tx = []

for j in range(fifo_size):
    for i in range(parallel_data_tx):
        vector_uart_tx.append(fpga_tx_matrix[i][j])

print("\nConvert a matrix to a flat vector.", vector_uart_tx)

hex_vector_uart = [eval(f"0x{num:02X}") for num in vector_uart_tx]   # vector_uart_tx

uart_tx_bytes = vector_to_uart_bytes(hex_vector_uart, Byte_size_tx, endianness='big')

hex_tx_list = []
hex_tx_list = [f"0x{byte:02X}" for byte in uart_tx_bytes]
print("\nTransmitted byte", hex_tx_list)

def print_vector_16_per_row(vector):
    print("\nFormatted Transmitted/Received data for visual data in hexadecimal:")
    for i in range(0, len(vector), 16):
        # Slice 16 elements per row
        row = vector[i:i+16]
        # Print each element with uniform spacing
        print("  ".join(f"{val:>6}" for val in row))


def send_data(data):
    """Send data over UART."""
    ser.write(data)  # Send data as bytes

def receive_data():
    """Receive data from UART."""
    response = ser.read(fifo_size * max(parallel_data_rx * Byte_size_rx, parallel_data_tx * Byte_size_tx))  # Read up to FIFO_size bytes (adjust as needed)
    hex_vector = [f"0x{byte:02X}" for byte in response]  # Convert each byte to a hex string
    print(f"\nReceived byte: {hex_vector}")
    print_vector_16_per_row(hex_tx_list)
    print_vector_16_per_row(hex_vector)
    return response



vector_2d = [[] for _ in range(parallel_data_rx)]

def reconstruct_2d_vector(array, parallel_data_rx):
    """Reconstruct 2D list from flat vector based on number of parallel channels."""
    return [
        [array[i] for i in range(pos, len(array), parallel_data_rx)]
        for pos in range(parallel_data_rx)
    ]


# ==============================    Data Transmitter and Receiver    ==================================== #
try:
    send_data(uart_tx_bytes) 
    #input("Please Enter to receive data for the FPGA......")
    response = receive_data()  # Receiving response from FPGA
    print("\nUART Received Vector (1D):", response)
    UART_rx = uart_bytes_to_vector(response, Byte_size_rx, endianness='big')
    print("\nUART Received Vector (1D):", UART_rx)
    print("UART Received Matrix (2D):")
    print(reconstruct_2d_vector(UART_rx, parallel_data_rx * FIFO_equality_ratio))
finally:
    ser.close()  # Close the serial connection
