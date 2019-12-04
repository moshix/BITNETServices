package main

/*
   chat v.0.5 Dec 4 2019
   a HNET (BITNET) chat daemon, starts and listens for input to a FIFO pipe
   defined in pipeFile
   invoke with:
   chat /path/pipefile defaultlogofftime
   (c) 2019 by moshix
   Program source is under Apache license             */

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"time"
)

// var pipeFile = "/tmp/chat.pipe"
var pipeFile = "/root/chat/chat.pipe"

// build list of users here, which will be used by all functions and features
// but possibly this structure is obsoleted by a map ... let's see.... lave for now
type users struct {
	useratnode   string
	lastmessage  string
	timer        int
	lastactivity int64
}

var table map[string]users

func main() {

	// alternative user list as a table
	table = make(map[string]users)

	fmt.Println("HNET chat server started....")
	file, err := os.OpenFile(pipeFile, os.O_CREATE, os.ModeNamedPipe)
	if err != nil {
		log.Fatal("Open named pipe file error:", err)
	} else {
		fmt.Print("FIFO pipe successfully opened and now listening\n")
	}

	reader := bufio.NewReader(file)

	for {
		line, err := reader.ReadBytes('\n')
		if err == nil {
			//fmt.Print("load string:" + string(line))
			readcommand(strings.TrimSuffix(string(line), "\n")) //pass incoming line to messager parser

		}
	}
}
func readcommand(fifoline string) {

	//fifomsgtime := time.Now()
	var fifouser string
	var fifomsg string
	var upperfifomsg string
	var upperfifouser string

	s := strings.Split(fifoline, ":")

	fifouser = s[0]
	fifomsg = s[1]                            //this is the payload part of the incoming msg
	upperfifomsg = strings.ToUpper(fifomsg)   //make upper case for commands processing
	upperfifouser = strings.ToUpper(fifouser) //make user upper case
	fmt.Printf("'%s' '%s'\n", upperfifouser, upperfifomsg)

	//at this point we have the user at node and the payload in fifomsg/upperfifomsg
	//now we start some very simple processing
	//---------------------------------------------------------------------------------
	//   /HELP sends to the user a help menu with ossibilities
	//   /WHO  sends a list of logged on (recently) users
	//   /LOGON logs the user on and adds her to the list
	//   /LOGOFF logs the user off and removes him from thelist
	//   /TIMER30  sets the timer to 30 min for inactive users
	//   /TIME60   sets the timer to 60 min for inactive users
	//   //STATS   sends usage statistics
	//---------------------------------------------------------------------------------

	switch upperfifomsg {
	case "/HELP":
		//		fmt.Println("This is the help case")
		break
	case "/WHO":
		//		fmt.Println("This is the WHO case")
		senduserlist(upperfifouser)
		break
	case "/STATS":
		//		fmt.Println("This is the STATS case")
		sendstats(upperfifouser)
		break
	case "/LOGON":
		//		fmt.Println("This is the LOGON case")
		adduser(upperfifouser)
		break
	case "/LOGOFF":
		//		fmt.Println("This is the LOGOFF case")
		deluser(upperfifouser)
		break
	default:
		// must be a regular chat message
		//user sending to broadcast LOGGED on?? if so  broadcast

		if _, ok := table[upperfifouser]; ok {
			broacastmsg(upperfifouser, fifomsg)
		} else {
			cmd := exec.Command("/usr/local/bin/send", upperfifouser, "You are not logged on currently to RELAY chat")
			_, err := cmd.CombinedOutput()
			if err != nil {
				log.Fatalf("cmd.Run() failed with %s\n", err)
			}

		}
	}
}

func senduserlist(upperfifouser string) {
	// looop thru user list and do
	// /var/user/bin/send -u chat@relay user1...99

	for user, _ := range table {
		cmd := exec.Command("/usr/local/bin/send", upperfifouser, "Online last 30min: ", user)
		_, err := cmd.CombinedOutput()
		if err != nil {
			log.Fatalf("cmd.Run() failed with %s\n", err)
		}

	}
}

func sendstats(user string) {
	// /var/user/bin/send -u chat@relay string of usage stats we collect here

}

func adduser(user string) {
	//add user to struct userlist and infor him he has been added
	// /var/user/bin/send -u chat@relay string of usage stats we collect here
	table[user] = users{
		lastactivity: time.Now().Unix(),
	}
	cmd := exec.Command("/usr/local/bin/send", user, " Welcome to RELAY CHAT v0.1.")
	_, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("cmd.Run() failed with %s\n", err)
	}

}

func deluser(user string) {
	//del user to struct userlist and infor him he has been added
	// /var/user/bin/send -u chat@relay string of usage stats we collect here
	delete(table, user)
	cmd := exec.Command("/usr/local/bin/send", user, " Goodbye from RELAY CHAT v0.1..")
	_, err := cmd.CombinedOutput()
	if err != nil {
		log.Fatalf("cmd.Run() failed with %s\n", err)
	}

}

func broacastmsg(upperfifouser string, fifomsg string) {
	//loop thru all user WHO HAVE NOT BEEN IDLE TOO long and
	// THE SEND COMMAND NEEDS TO BE LIKE THIS: /usr/local/bin/send user fifommsg
	//	 for username, userStruct := range table {
	//	 if userStruct.lastActivity `is before 30 minutes` {
	//	 	-->> QUESTION?   delete(table, username)   HOW DO I DO TIME.NOW-30M ?
	// }
	//	 }
	for upperfifouser, _ := range table {
		if _, ok := table[upperfifouser]; ok {
			cmd := exec.Command("/usr/local/bin/send", upperfifouser, fifomsg)
			_, err := cmd.CombinedOutput()
			if err != nil {
				log.Fatalf("cmd.Run() failed with %s\n", err)
			}

		}
	}
}

// end of chat program here
