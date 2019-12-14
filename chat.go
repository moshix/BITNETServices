package main

/*
   chat v.0.9.6 Dec 5 2019
   a HNET (BITNET) chat daemon, starts and listens for input to a FIFO pipe
   defined in pipeFile
   invoke with:
   chat &
   (c) 2019 by moshix
   Program source is under Apache license             */

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

// change this to suit your needs
const pipeFile = "/root/chat/chat.pipe"

const sendCommand = "/usr/local/bin/send"

var msgcount int64  // total messages sent, used by /STATS command
var totaluser int64 // total users logged in, used by /STATS command
//var prevmsg1 string  // last message for loop detector
//var prevmsg2 string // before last message

type users struct {
	useratnode   string //user@node
	lastmessage  string //what was the last message setn by this user
	timer        int    //what is this users desired logoff timer
	lastactivity int64  //updated every time this user does something
}

var table map[string]users // map of structs of all logged on users

func main() {
	table = make(map[string]users)

	fmt.Println("HNET chat server started....")
	file, err := os.OpenFile(pipeFile, os.O_CREATE, os.ModeNamedPipe)
	if err != nil {
		log.Fatal("Open named pipe file error:", err)
	} else {
		fmt.Print("FIFO pipe successfully opened and now listening\n")
	}

	// here is the pipe listening to all incoming messages
	reader := bufio.NewReader(file)
	for {
		line, err := reader.ReadBytes('\n')
		if err == nil {
			readcommand(strings.TrimSuffix(string(line), "\n")) //pass incoming line to messager parser

		}
		time.Sleep(400 * time.Millisecond) // wait a bit to avoid excessive CPU usage
	}
}

func send(arg ...string) {
	cmd := exec.Command(sendCommand, arg...)
	if _, err := cmd.CombinedOutput(); err != nil {
		log.Fatalf("send failed with %s\n", err)
	}
	msgcount++
}

func readcommand(fifoline string) {

	var fifouser string
	var fifomsg string
	var upperfifomsg string
	var upperfifouser string

	s := strings.Split(fifoline, "}") //split this message into sender and msg content

	fifouser = s[0]
	fifomsg = s[1]                            //this is the payload part of the incoming msg
	upperfifomsg = strings.ToUpper(fifomsg)   //make upper case for commands processing
	upperfifouser = strings.ToUpper(fifouser) //make user upper case
	fmt.Printf("'%s' '%s'\n", upperfifouser, fifomsg)

	//at this point we have the user at node and the payload in fifomsg/upperfifomsg
	//now we start some very simple processing
	//---------------------------------------------------------------------------------
	//   /HELP sends to the user a help menu with ossibilities
	//   /WHO  sends a list of logged on (recently) users
	//   /LOGON logs the user on and adds her to the list
	//   /LOGOFF logs the user off and removes him from thelist
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

		if _, ok := table[upperfifouser]; ok {
			table[user] = users{
				lastactivity: time.Now().Unix(),
			}
			broacastmsg(upperfifouser, fifouser, fifomsg)
		} else {
			send(upperfifouser, "You are not logged on currently to RELAY chat")
		}
	}
}

func senduserlist(upperfifouser string) {

	for user := range table {
		send(upperfifouser, "Online last 120 min: ", user)
	}
}

func sendstats(user string) {
	s := strconv.FormatInt(msgcount, 10)
	t := strconv.FormatInt(totaluser, 10)
	send(user, " Total messages: ", s, "     Total users:", t)
}

func adduser(user string) {
	table[user] = users{
		lastactivity: time.Now().Unix(),
	}
	send(user, " Welcome to RELAY CHAT v0.9.6")
	totaluser++
}

func deluser(user string) {
	delete(table, user)
	send(user, " Goodbye from RELAY CHAT v0.9.6")
}

func broacastmsg(upperfifouser string, fifouser string, fifomsg string) {

	// remove users inactive for 120  minutes
	thirtyMinutesAgo := time.Now().Add(time.Duration(-120) * time.Minute).Unix()
	for username, userStruct := range table {
		if userStruct.lastactivity < thirtyMinutesAgo {
			log.Printf("Deleting inactive user '%s'", username)
			delete(table, username)
		}
	}

	loopmsg := fifomsg[0:3] //this is the begignning of a user who is not logged on anymore
	//Looping messages begin with DMT, filter those
	if loopmsg == "DMT" {
		delete(table, upperfifouser)
	}
	for upperfifouser := range table {
		if _, ok := table[upperfifouser]; ok {
			send(upperfifouser, "> ", fifouser, fifomsg)
		}
	}
}
