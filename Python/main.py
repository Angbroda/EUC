import tkinter as tk
from tkinter import ttk, CENTER
from pyad import pyad

usersAD = {}
def showContextMenu(event):
    # Display the context menu at the current mouse position
    getUserGroupsFromSelection(event)
    contextMenu.post(event.x_root, event.y_root)
    contextMenu.grab_current()
    contextMenu.delete(0, "end")
    print(event)

# TODO
def getUserGroupsFromSelection(event):
    selection = int(tree.selection()[0])
    userSelected = usersAD[selection]
    userGroups = userSelected.get_attribute("memberOf")
    print(userGroups)
    extractedValues = []
    for groupString in userGroups:
        _, value = groupString.split(",")[0].split("=")
        extractedValues.append(value)
        contextMenu.add_command(label=value)

# Function to load users from a file
def loadUsers():
    check_button.config(state="normal")
    usersAD.clear()
    userIndex = -1
    for i in tree.get_children():
        tree.delete(i)
    try:
        # Get user lists
        with open("user_list.txt", "r",encoding='UTF-8') as userFile:
            users = userFile.read().splitlines()

        # Check if user exists in AD
        for index, username in enumerate(users):
            user = pyad.from_cn(username)
            userIndex+=1
            if user is not None:
                print(userIndex)
                tree.insert('', index, index, values=(username, "YES",""))
                usersAD[index] = user
            else:
                usersAD[index] = username
                print(index)
                tree.insert('',index, index, values=(username, "NO",""))
    except Exception as e:
        print("Error reading user list: ",e)
    print(usersAD)

# Function to check if a user is in a group
def checkUsersInGroup():
    groupname = groupname_entry.get()

    for index, username in enumerate(usersAD.items()):
        try:
            userGroups = username[1].get_attribute("memberOf")
            extractedValues = []
            for groupString in userGroups:
                _, value = groupString.split(",")[0].split("=")
                extractedValues.append(value)
        except:
            groupname = "NOT IN GROUP"

        if groupname in extractedValues:
            veryMuchTest = tree.get_children()
            tree.set(veryMuchTest[index], 2, "YES")
        else:
            veryMuchTest = tree.get_children()
            tree.set(veryMuchTest[index], 2, "NO")

    #result_text.config(state="disabled")

# Create the main application window
app = tk.Tk()
app.title("User Group Checker")

# Create and configure widgets
groupname_label = tk.Label(app, text="Enter Group Name:")
groupname_label.pack()
groupname_entry = tk.Entry(app)
groupname_entry.pack()

load_button = tk.Button(app, text="Load User List", command=loadUsers)
load_button.pack()

check_button = tk.Button(app, text="Check group", command=checkUsersInGroup)
# Disable the button
check_button.config(state="disabled")
check_button.pack()

tree = ttk.Treeview(app, column=("c1", "c2","c3"), show= 'headings')
tree.column("# 1",anchor=CENTER)
tree.heading("# 1", text= "USER")
tree.column("# 2", anchor= CENTER)
tree.heading("# 2", text= "FOUND")
tree.column("# 3", anchor= CENTER)
tree.heading("# 3", text="HAS GROUP")
tree.pack()
#result_text.config(state="disabled")

# Create a context menu
contextMenu = tk.Menu(app, tearoff=0)
contextMenu.add_command(label='Label here', command=getUserGroupsFromSelection)

# Bind a function to the selection event
#tree.bind('<ButtonRelease-1>', onSelect)

# Bind the right mouse button event to show the context menu
tree.bind('<Button-3>',showContextMenu)

# Start the GUI main loop
app.mainloop()
