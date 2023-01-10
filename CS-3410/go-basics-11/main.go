package thefarm

import (
	"errors"
	"fmt"
)

// See types.go for the types defined for this exercise.

// TODO: Define the SillyNephewError type here.
type SillyNephewError struct {
	Cows int
}

func (e *SillyNephewError) Error() string {
	return fmt.Sprintf("silly nephew, there cannot be %d cows", e.Cows)
}

// DivideFood computes the fodder amount per cow for the given cows.
func DivideFood(weightFodder WeightFodder, cows int) (float64, error) {
	amount, err := weightFodder.FodderAmount()
	fmt.Println("inital amount: ", amount)
	fmt.Println("inital error: ", err)
	if err != nil {
		if amount > 0 && err == ErrScaleMalfunction {
			amount *= 2
		} else if amount >= 0 {
			amount = 0
			return amount, err
		}
	}
	if cows == 0 {
		err = errors.New("division by zero")
		amount = 0.0
		return amount, err
	}
	if cows < 0 {
		err = &SillyNephewError{cows}
		amount = 0.0
		return amount, err
	}
	if amount < 0 {
		amount = 0
		err = errors.New("negative fodder")
		return amount, err
	}
	err = nil
	amount /= float64(cows)
	fmt.Println("err: ", err)
	fmt.Println("amount: ", amount)
	return amount, err
}
