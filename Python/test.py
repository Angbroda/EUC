import tkinter as tk
from tkinter import ttk

def on_select(event):
    selected_item = tree.selection()[0]
    values = tree.item(selected_item, 'values')
    print("Selected:", values)

def reset_occupation():
    # Iterate through all items and set the 'Occupation' column to '0'
    for item in tree.get_children():
        tree.set(item, 2, '0')

def show_context_menu(event):
    # Display the context menu at the current mouse position
    context_menu.post(event.x_root, event.y_root)

# Create the main window
root = tk.Tk()
root.title("Treeview Example")

# Create a Treeview widget
tree = ttk.Treeview(root, columns=('Name', 'Age', 'Occupation'))

# Define columns
tree.heading('#0', text='ID')
tree.heading('Name', text='Name')
tree.heading('Age', text='Age')
tree.heading('Occupation', text='Occupation')

# Add data to the Treeview
tree.insert('', 'end', values=('1', 'John Doe', '25', 'Engineer'))
tree.insert('', 'end', values=('2', 'Jane Smith', '30', 'Doctor'))
tree.insert('', 'end', values=('3', 'Bob Johnson', '22', 'Student'))

# Bind a function to the selection event
tree.bind('<ButtonRelease-1>', on_select)

# Create a context menu
context_menu = tk.Menu(root, tearoff=0)
context_menu.add_command(label='Reset Occupation', command=reset_occupation)

# Bind the right mouse button event to show the context menu
tree.bind('<Button-3>', show_context_menu)

# Pack the Treeview widget
tree.pack(expand=True, fill='both')

# Run the Tkinter event loop
root.mainloop()
