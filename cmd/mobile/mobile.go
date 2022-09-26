package mobile

import (
	"fmt"
	"time"
)

// SayHi returns a greeting message for the given name.
func SayHi(name string) (string, error) {
	return fmt.Sprintf("Hi %s!", name), nil
}

// SayHiWithDuration returns a greeting message for the given name, but simulates a heavier task by sleeping for the
// given duration, before the greeting is returned.
func SayHiWithDuration(name, duration string) (string, error) {
	parsedDuration, err := time.ParseDuration(duration)
	if err != nil {
		return "", err
	}

	time.Sleep(parsedDuration)

	return fmt.Sprintf("Hi %s!", name), nil
}
