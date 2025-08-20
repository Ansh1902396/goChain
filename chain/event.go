package chain

type EventType uint64

const (
	EvAll   EventType = 0
	EvTx    EventType = 1
	EvBlock EventType = 2
)

type Event struct {
	Type   EventType `json:"type"`
	Action string    `json:"action"`
	Body   []byte    `json:"body"`
}
