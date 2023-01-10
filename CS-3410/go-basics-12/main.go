package circular

// Implement a circular buffer of bytes supporting both overflow-checked writes
// and unconditional, possibly overwriting, writes.
//
// We chose the provided API so that Buffer implements io.ByteReader
// and io.ByteWriter and can be used (size permitting) as a drop in
// replacement for anything using that interface.

import (
	"errors"
)

// Define the Buffer type here.

type Buffer struct {
	buf chan byte
	cap int
}

func NewBuffer(size int) *Buffer {
	buf := Buffer{make(chan byte, size), size}
	return &buf
}

func (b *Buffer) ReadByte() (byte, error) {
	if len(b.buf) == 0 {
		return 0x0, errors.New("empty")
	}
	return <-b.buf, nil
}

func (b *Buffer) WriteByte(c byte) error {
	if len(b.buf) == cap(b.buf) {
		return errors.New("full")
	}
	b.buf <- c
	return nil
}

func (b *Buffer) Overwrite(c byte) {
	err := b.WriteByte(c)
	if err != nil {
		<-b.buf
		b.buf <- c
	}
}

func (b *Buffer) Reset() {
	b.buf = make(chan byte, b.cap)
}
