package main

// #include <stdlib.h>
import "C"

import (
	"fmt"
	"time"
	"unsafe"

	"github.com/ricoberger/go-flutter/cmd/desktop/dart_api_dl"
)

// Init is used to initalize the Dart API and must be called before any other exported function.
//
//export Init
func Init(api unsafe.Pointer) {
	dart_api_dl.Init(api)
}

// FreePointer can be used to free a returned pointer.
//
//export FreePointer
func FreePointer(ptr *C.char) {
	C.free(unsafe.Pointer(ptr))
}

// SayHi returns a greeting message for the given name.
//
//export SayHi
func SayHi(port C.long, nameC *C.char, nameLen C.int) {
	name := C.GoStringN(nameC, nameLen)

	go sayHi(int64(port), name)
}

func sayHi(port int64, name string) {
	dart_api_dl.SendToPort(port, fmt.Sprintf("Hi %s!", name))
}

// SayHiWithDuration returns a greeting message for the given name, but simulates a heavier task by sleeping for the
// given duration, before the greeting is returned.
//
//export SayHiWithDuration
func SayHiWithDuration(port C.long, nameC *C.char, nameLen C.int, durationC *C.char, durationLen C.int) {
	name := C.GoStringN(nameC, nameLen)
	duration := C.GoStringN(durationC, durationLen)

	go sayHiWithDuration(int64(port), name, duration)
}

func sayHiWithDuration(port int64, name, duration string) {
	parsedDuration, err := time.ParseDuration(duration)
	if err != nil {
		dart_api_dl.SendToPort(port, fmt.Sprintf("Error: %s", err.Error()))
		return
	}

	time.Sleep(parsedDuration)

	dart_api_dl.SendToPort(port, fmt.Sprintf("Hi %s!", name))
}

func main() {}
