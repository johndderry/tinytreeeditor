#include <alsa/asoundlib.h>
#include "midi.h"


snd_seq_queue_status_t *status;
snd_seq_t *seq_handle;
int in_port, out_port, aux_port;
int queue, metronome;

int init_midi() {
	snd_seq_open(&seq_handle, "default", SND_SEQ_OPEN_INPUT | SND_SEQ_OPEN_OUTPUT, 0);

    snd_seq_set_client_name(seq_handle, "tte");
    in_port = snd_seq_create_simple_port(seq_handle, "in",
                      SND_SEQ_PORT_CAP_WRITE|SND_SEQ_PORT_CAP_SUBS_WRITE,
                      SND_SEQ_PORT_TYPE_APPLICATION);
	
    out_port = snd_seq_create_simple_port(seq_handle, "out",
                      SND_SEQ_PORT_CAP_READ|SND_SEQ_PORT_CAP_SUBS_READ,
                      SND_SEQ_PORT_TYPE_APPLICATION);	

    aux_port = snd_seq_create_simple_port(seq_handle, "aux",
                      SND_SEQ_PORT_CAP_WRITE, SND_SEQ_PORT_TYPE_APPLICATION);	

	if( in_port < 0 || out_port < 0 || aux_port < 0 ) {
		fprintf(stderr, "failure initalizing midi\n");
		return -1;
	}

	snd_seq_queue_status_malloc(&status);
	queue = -1;
	metronome = 0;
	return 0;
}

void close_midi() {
	snd_seq_queue_status_free(status);
	snd_seq_delete_simple_port( seq_handle, in_port );
	snd_seq_delete_simple_port( seq_handle, out_port );
	snd_seq_delete_simple_port( seq_handle, aux_port );
}

void midi_event( int type, int echo, unsigned timestamp, int chan, int note, int veloc ) {
	
	snd_seq_event_t event;
	snd_seq_ev_clear( &event );
	switch( type ) {
		case NOTE_ON: snd_seq_ev_set_noteon( &event, chan, note, veloc); break;
		case NOTE_OFF: snd_seq_ev_set_noteoff( &event, chan, note, veloc); break;
		case PROG_CHANGE: snd_seq_ev_set_pgmchange( &event, chan, note); break;
		default: fprintf(stderr, "midi event %d not handled\n", type); return;
	}
	if( queue < 0 )
		snd_seq_ev_schedule_tick( &event, SND_SEQ_QUEUE_DIRECT, 0, timestamp );
	else
		snd_seq_ev_schedule_tick( &event, queue, 0, timestamp );

	snd_seq_addr_t addr;
	addr.client = snd_seq_client_id( seq_handle );
	addr.port = out_port;	
	event.source = addr;
	
	addr.client = SND_SEQ_ADDRESS_SUBSCRIBERS;
	addr.port = 0;
	event.dest = addr;
	
	snd_seq_event_output( seq_handle, &event );
	
	if( echo ) {
		addr.client = snd_seq_client_id( seq_handle );
		addr.port = aux_port;
		event.dest = addr;
		
		snd_seq_event_output( seq_handle, &event );
	}
}

void queue_on() {
	queue = snd_seq_alloc_queue( seq_handle );
      /* set timestamp info of input port  */
      snd_seq_port_info_t *pinfo;
      snd_seq_port_info_alloca(&pinfo);
      snd_seq_get_port_info( seq_handle, in_port, pinfo );
      snd_seq_port_info_set_timestamping(pinfo, 1);
      snd_seq_port_info_set_timestamp_queue(pinfo, queue );
      //snd_seq_port_info_set_timestamp_real( pinfo, 1 );
      snd_seq_set_port_info( seq_handle, in_port, pinfo );	

}

void queue_off() {
	snd_seq_free_queue( seq_handle, queue );	
	queue = -1;	
     /* turn off timestamping of input port  */
      snd_seq_port_info_t *pinfo;
      snd_seq_port_info_alloca(&pinfo);
      snd_seq_get_port_info( seq_handle, in_port, pinfo );
      snd_seq_port_info_set_timestamping(pinfo, 0);
      snd_seq_set_port_info( seq_handle, in_port, pinfo );		
}

void queue_clear() {
	if( queue < 0 ) return;
	
	snd_seq_stop_queue( seq_handle, queue, NULL );
	snd_seq_drain_output( seq_handle );

	snd_seq_remove_events_t *remove;
	snd_seq_remove_events_malloc(&remove);
	snd_seq_remove_events_set_queue(remove, queue);
	snd_seq_remove_events_set_condition(remove, SND_SEQ_REMOVE_OUTPUT | SND_SEQ_REMOVE_IGNORE_OFF);
	snd_seq_remove_events(seq_handle, remove);
	snd_seq_remove_events_free(remove);
	
	snd_seq_continue_queue( seq_handle, queue, NULL );
	snd_seq_drain_output( seq_handle );	
}

snd_seq_tick_time_t get_tick( int *events) {
	
	snd_seq_get_queue_status(seq_handle, queue, status);
	int tick = snd_seq_queue_status_get_tick_time(status);
	*events = snd_seq_queue_status_get_events( status );  
	return tick;
}

void set_tempo( int bpm ) {
	
	snd_seq_queue_tempo_t *tempo;

	snd_seq_queue_tempo_malloc(&tempo);
	int t = (int)(6e7 / ((double)bpm * (double)TICKS_PER_QUARTER) * (double)TICKS_PER_QUARTER);
	snd_seq_queue_tempo_set_tempo(tempo, t);
	snd_seq_queue_tempo_set_ppq(tempo, TICKS_PER_QUARTER);
	snd_seq_set_queue_tempo(seq_handle, queue, tempo);
	snd_seq_queue_tempo_free(tempo);
}

