# 🧠 NeuralNetwork_ASM

A **simple neural network** implemented in **x86 Assembly** (Linux NASM).  
Yep, you read that right — neural nets *without* Python, TensorFlow, or magic libraries. Just raw, glorious assembly!

---

## 📁 What’s in the Repo?

- `forward_propagation_XOR.asm` – The main assembly file (written in NASM, 32-bit).
- `model.txt` – Contains model weights and biases in raw float byte format.
- `script.py` – Python script to:
  - Convert `model.txt` bytes into human-readable values
  - Read the result from the neural net after it runs
  - Print outputs in a nice way

---

## ⚙️ Requirements

- **Linux (x86)** or use **WSL** on Windows
- **NASM** installed  
  Install via:
  ```bash
  sudo apt-get install nasm
  ```

---

## 🛠️ How to Build & Run

1. **Assemble and Link:**
   ```bash
   nasm -f elf32 forward_propagation_XOR.asm -o forward_propagation_XOR.o
   ld -m elf_i386 forward_propagation_XOR.o -o forward_propagation_XOR
   ```

2. **Run it:**
   ```bash
   ./forward_propagation_XOR
   ```

   This will run the neural network and output the results to a file called `result.txt` in float raw bytes.
   Note: If `result.txt` file is not created please create the file than run the asm.

---

## 🐍 View the Output with Python

Use the provided `script.py` to read the output in a human-friendly format.

### Show the result:
```bash
python script.py result.txt
```

### Show the input (model):
```bash
python script.py model.txt
```

### Show both:
```bash
python script.py result.txt model.txt
```
or
```bash
python script.py model.txt result.txt
```

Either order works — script's chill like that 😄

---

## 🐛 Debugging (Like a Pro Hacker 💻)

If you're feeling brave or curious and wanna dive into debugging in assembly, here’s some tips:

### 🔧 Launch GDB

Start debugging your binary with:
```bash
gdb ./forward_propagation_XOR
```

### 🛠️ Useful GDB Commands

- **Set a breakpoint:**
  ```bash
  break <label>       # or break *0x08048000 (specific address)
  ```
- **Run the program:**
  ```bash
  run
  ```
- **Step through instructions:**
  ```bash
  stepi               # Step one instruction at a time
  nexti               # Step over instructions
  ```
- **Inspect current instruction:**
  ```bash
  x/i $eip
  ```
- **View memory as floats:**
  ```bash
  x/1f <address>      # View 1 float (4 bytes)
  x/4f <address>      # View 4 floats
  ```
- **Display registers:**
  ```bash
  info registers
  info float
  ```
- **See all breakpoints:**
  ```bash
  info breakpoints
  ```

### 🧙 Bonus: Split View for Assembly

Get the classic side-by-side view with:
```bash
layout asm
```

You’ll feel like you're in a retro hacking movie 🔥

---

## 💬 Notes

- This is a **learning project**, so expect some quirks and rough edges.
- Building a neural net in assembly is... kinda nuts (in the best way).
- Big respect if you're here trying to understand or improve it 💪

---

## 📜 References

- [x86 Instruction Reference by Félix Cloutier](https://www.felixcloutier.com/x86/)
