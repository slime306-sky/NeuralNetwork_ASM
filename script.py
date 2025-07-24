import sys
import struct
import numpy as np
import os

def load_model(filename, HIDDEN, INPUTS, OUTPUTS):
    with open(filename, "rb") as f:
        # Read weights for hidden layer
        wh = np.fromfile(f, dtype=np.float32, count=HIDDEN * INPUTS).reshape((HIDDEN, INPUTS))

        # Read biases for hidden layer
        bh = np.fromfile(f, dtype=np.float32, count=HIDDEN)

        # Read weights for output layer
        wo = np.fromfile(f, dtype=np.float32, count=OUTPUTS * HIDDEN).reshape((OUTPUTS, HIDDEN))

        # Read biases for output layer
        bo = np.fromfile(f, dtype=np.float32, count=OUTPUTS)

    print("🧠 Model loaded, woohoo! 🎉")
    return wh, bh, wo, bo

def show_model_data(filename):
    HIDDEN = 2
    INPUTS = 2
    OUTPUTS = 1
    print(f"🔍 Loading model from '{filename}'...")
    wh, bh, wo, bo = load_model(filename, HIDDEN, INPUTS, OUTPUTS)
    
    print("\n🎯 Model Parameters:\n")
    print("\n🔹 Weights (Hidden Layer):\n", wh)
    print("\n🔹 Biases (Hidden Layer):\n", bh)
    print("\n🔹 Weights (Output Layer):\n", wo)
    print("\n🔹 Biases (Output Layer):\n", bo)

def show_result_data(filename):
    print(f"📦 Reading output from '{filename}'...")
    try:
        with open(filename, "rb") as f:
            data = f.read()

        if len(data) != 16:
            print("🚫 Whoa! Output file is the wrong size.")
            print(f"Expected 16 bytes but got {len(data)} bytes.")
        else:
            output = struct.unpack("ffff", data)
            print("📄 Raw bytes (hex):", data.hex())

            print("\n📊 Outputs:")
            for i, val in enumerate(output):
                print(f"🔸 Output #{i + 1}: {val:.6f}")
    except FileNotFoundError:
        print("😬 File not found:", filename)

def main():
    if len(sys.argv) < 2:
        print("🧐 Umm... you gotta tell me what to do!")
        print("Usage:")
        print("  python script.py result_file")
        print("  python script.py model_file")
        print("  python script.py result_file model_file")
        return

    args = sys.argv[1:]
    for arg in args:
        if not os.path.exists(arg):
            print(f"❓ File '{arg}' not found.")
            continue

        if "result" in arg.lower():
            show_result_data(arg)
        elif "model" in arg.lower() or "output" in arg.lower():
            show_model_data(arg)
        else:
            print(f"🤷 Hmm, not sure what '{arg}' is. Skipping!")

if __name__ == "__main__":
    main()
