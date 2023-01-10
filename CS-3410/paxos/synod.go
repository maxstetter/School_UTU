package main

import(
	"bufio"
	"fmt"
	"strings"
	"log"
	"os"
)

type Key struct{
	Type int
	Time int
	Target int
}

//maybe make a struct of proposers

type Node struct{
	Id int
	Proposal int
	Time int
	Voted bool
	np int
	na int
}

type State struct {
	nodes []Node
	Info map[Key]string
	Decided bool
}

func (s *State) TryInitialize(line string) bool{
	/////////Use size to determine how many nodes to create.
	var size int
	n, err := fmt.Sscanf(line, "initialize %d nodes\n",&size)
	if err != nil || n != 1 || size < 3 || size > 9{
		return false
	}
	for i := 0; i < size; i++{
		var nodie Node
		nodie.Id = i + 1
		nodie.Time = 0
		nodie.Voted = false
		s.nodes = append(s.nodes, nodie)
	}
	fmt.Printf("--> initialized %d nodes\n", size)
	return true
}

func (s *State) TrySendPrepare(line string) bool{
	//use timestamp and node to do a prepare request.
	var node int
	var timestamp int
	n, err := fmt.Sscanf(line, "at %d send prepare request from %d\n", &timestamp, &node)
	if err != nil || n != 2{
		return false
	}
	//////////////while s.Decide = false
	size := len(s.nodes)
	majority := size / 2 + 1 ////////////move to state object
	tally := 0
	// check each Node in the slice of nodes within state.
	// If Node.Decided == true, add to tally
	for i := 0; i < size; i++{
		if s.nodes[i].Voted == true{
			tally += 1
		}else if s.nodes[i].Voted == false{
//			fmt.Printf("Did not vote\n")
		}
	}
	if tally >= majority{
		//go to accept round
	}
	s.nodes[node-1].Time = timestamp
	//for proposal increment 10. for every round increment 100?
	proposal := 5000 + node
	s.nodes[node-1].Proposal = proposal
	fmt.Printf("--> sent prepare requests to all nodes from %d with sequence %d\n", node, proposal)
	return true
}

func (s *State) TryDeliverPrepareRequest(line string) bool{
	var timetarget int
	var target int
	var fromtime int
	var nodie Node
	n, err := fmt.Sscanf(line, "at %d deliver prepare request message to %d from time %d\n", &timetarget, &target, &fromtime)
	if err != nil || n != 3{
		return false
	}
	//search the slice of nodes for a matching fromtime.
	for _, v := range s.nodes{
		if v.Time == fromtime{
			nodie = v
		}
	}
	//////// test for majority here //////////
	targetnode := s.nodes[target-1]
	if nodie.Proposal > targetnode.Proposal{
		targetnode.Proposal = nodie.Proposal
		fmt.Printf("reply prepare_ok\n")
	}
	fmt.Printf("------------> prepare request from %d sequence %d accepted by %d with no value\n", nodie.Id, nodie.Proposal , target)
	return true
}


func (s *State) TryDeliverPrepareResponse(line string) bool{
	//use timetarget, fromtime and target to deliver a prepare respose.
	var timetarget int
	var target int
	var fromtime int
	n, err := fmt.Sscanf(line, "at %d deliver prepare response message to %d from time %d\n", &timetarget, &target, &fromtime)
	if err != nil || n != 3{
		return false
	}
	////if target.time is > fromtime then fromtime = target.time reply prepare ok
	////else reply reject
//	for _, v := range s.nodes{
//		if v.np >
//	}
//	if s.nodes[target-1].Time > fromtime{
//		s.nodes np = fromtime
//		//highest seen = fromtime
//	}
//	fmt.Printf("asdfasdfasdf\n")

//////////check for duplicate messages.
	return true
}

func (s *State) TryAcceptRequest(line string) bool{
	//use timetarget, fromtime and target to deliver a prepare request.
	var timetarget int
	var target int
	var fromtime int
	n, err := fmt.Sscanf(line, "at %d deliver accept request message to %d from time %d\n", &timetarget, &target, &fromtime)
	if err != nil || n != 3{
		return false
	}
	return true
}

func (s *State) TryAcceptResponse(line string) bool{
	//use timetarget, fromtime and target to deliver a prepare request.
	var timetarget int
	var target int
	var fromtime int
	n, err := fmt.Sscanf(line, "at %d deliver accept response message to %d from time %d\n", &timetarget, &target, &fromtime)
	if err != nil || n != 3{
		return false
	}
	// Use network map to identify messages.
	return true
}

func (s *State) TryDecideRequest(line string) bool{
	//use timetarget, fromtime and target to deliver a prepare request.
	var timetarget int
	var target int
	var fromtime int
	n, err := fmt.Sscanf(line, "at %d deliver decide request message to %d from time %d\n", &timetarget, &target, &fromtime)
	if err != nil || n != 3{
		return false
	}
	return true
}


//////////////// MAIN LOOP /////////////////////////////
func main(){
	var state State

	scanner := bufio.NewScanner(os.Stdin)
//	fmt.Printf("os.Stdin: ", os.Stdin)

	for scanner.Scan(){
		line := scanner.Text()
		//trim comments
		if i := strings.Index(line, "//"); i >= 0{
			line = line[:i]
		}
		//ignore empty/comment-only lines
		if len(strings.TrimSpace(line)) == 0 {
			continue
		}

		line += "\n"
		switch{
			case state.TryInitialize(line):
			case state.TrySendPrepare(line):
			case state.TryDeliverPrepareRequest(line):
			case state.TryDeliverPrepareResponse(line):
			case state.TryAcceptRequest(line):
			case state.TryAcceptResponse(line):
			case state.TryDecideRequest(line):
			default:
				log.Fatalf("Unknown line: %s", line)
		}
	}
	if err := scanner.Err(); err != nil {
		log.Fatalf("Scanner Failure: %v", err)
	}
}
