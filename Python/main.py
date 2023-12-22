import tkinter as tk
from tkinter import ttk, CENTER
from pyad import pyad

usersAD = {}
def loadUsers():
    check_button.config(state="normal")
    usersAD.clear()
    userIndex = -1
    for i in result_text.get_children():
        result_text.delete(i)
    try:
        with open("user_list.txt", "r",encoding='UTF-8') as userFile:
            users = userFile.read().splitlines()
        for username in users:
            user = pyad.from_cn(username)
            userIndex+=1
            if user is not None:
                print(userIndex)
                result_text.insert('', userIndex,text= "1",values=(username, "YES",""))
                usersAD[user] = userIndex
            else:
                usersAD[username] = userIndex
                print(userIndex)
                result_text.insert('',userIndex, userIndex,text= "1",values=(username, "NO",""))
    except Exception as e:
        print("Error reading user list: ",e)
    print(usersAD)

# Function to check if a user is in a group
def checkUsersInGroup():
    groupname = groupname_entry.get()
    #for i in result_text.get_children():
    #    result_text.delete(i)
        #result_text.set(my_row_id, column=my_column_id, value=my_new_value)
    for username, indexOfUser in usersAD.items():
        try:
            userGroups = username.get_attribute("memberOf")
        except:
            groupname = "NOT IN GROUP"
        extractedValues = []
        for groupString in userGroups:
            _, value = groupString.split(",")[0].split("=")
            extractedValues.append(value)

        print("ASC    ",result_text.column("# 2"))
        if groupname in extractedValues:
            result_text.set("c2", "c2",("A"))
        else:
            result_text.set("c2", "c2",("O"))

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

result_text = ttk.Treeview(app, column=("c1", "c2","c3"), show= 'headings')
result_text.column("# 1",anchor=CENTER)
result_text.heading("# 1", text= "USER")
result_text.column("# 2", anchor= CENTER)
result_text.heading("# 2", text= "FOUND")
result_text.column("# 3", anchor= CENTER)
result_text.heading("# 3", text="HAS GROUP")
result_text.pack()
#result_text.config(state="disabled")

# Start the GUI main loop
app.mainloop()
