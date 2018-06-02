#define NOTE_ON		1
#define NOTE_OFF	2
#define PROG_CHANGE	3

#define TICKS_PER_QUARTER 96

extern snd_seq_t *seq_handle;
extern int in_port, out_port, aux_port;
extern int queue, metronome;

extern int init_midi();
extern void close_midi();
extern void midi_event( int, int, unsigned, int, int, int );
extern void queue_clear();
extern void queue_on();
extern void queue_off();
extern void set_tempo(int);
extern snd_seq_tick_time_t get_tick( int *);


