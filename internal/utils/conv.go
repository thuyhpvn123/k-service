package utils

import "strconv"

func FloatToString(amount float64, prec int) string {
	return strconv.FormatFloat(amount, 'f', prec, 64)
}
