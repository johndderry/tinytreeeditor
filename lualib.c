#include <stdio.h>
#include <stdlib.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include <alsa/asoundlib.h>
#include "midi.h"

/*
 * ALSA wrapper stuff
 * 
*/

/* STUBS
 * These are stubs, to be redefined by user in main.lua
 */
static int alsa_click(lua_State *L) {
	
}
 
static int alsa_noteon(lua_State *L) {
	
	int chan = lua_tointeger(L, 1);
	int note = lua_tointeger(L, 2);
	int velocity = lua_tointeger(L, 3);
	double dtimestamp = lua_tonumber(L, 4);

	lua_getglobal(L, "alsa");
	lua_getfield(L, -1, "sendnoteon");
	lua_pushinteger(L, chan );
	lua_pushinteger(L, note );
	lua_pushinteger(L, velocity );
	lua_pushnumber(L, dtimestamp );
	lua_pcall(L, 4, 0, 0);

	lua_getfield(L, -1, "drain");
	lua_pcall(L, 0, 0, 0);
	
	lua_pop(L, 1);
	return 0;
}

static int alsa_noteoff(lua_State *L) {
	
	int chan = lua_tointeger(L, 1);
	int note = lua_tointeger(L, 2);
	int velocity = lua_tointeger(L, 3);
	double dtimestamp = lua_tonumber(L, 4);

	lua_getglobal(L, "alsa");
	lua_getfield(L, -1, "sendnoteoff");
	lua_pushinteger(L, chan );
	lua_pushinteger(L, note );
	lua_pushinteger(L, velocity );
	lua_pushnumber(L, dtimestamp );
	lua_pcall(L, 4, 0, 0);

	lua_getfield(L, -1, "drain");
	lua_pcall(L, 0, 0, 0);
	
	lua_pop(L, 1);
	return 0;
}


static int alsa_program(lua_State *L) {
	return 0;
}

/*
 * WRAPPER
 * These are the wrapper functions
 */

 static int alsa_init(lua_State *L) {

  init_midi();
  
  return 0;
}

static int alsa_close(lua_State *L) {

  close_midi();
  
  return 0;
}

static int alsa_sendnoteon(lua_State *L) {
	
	int chan = lua_tointeger(L, 1);
	int note = lua_tointeger(L, 2);
	int velocity = lua_tointeger(L, 3);
	double dtimestamp = lua_tonumber(L, 4);
	
	midi_event( NOTE_ON, 0, (unsigned) dtimestamp, chan, note, velocity);
	return 0;
}

static int alsa_sendnoteoff(lua_State *L) {
	
	int chan = lua_tointeger(L, 1);
	int note = lua_tointeger(L, 2);
	int velocity = lua_tointeger(L, 3);
	double dtimestamp = lua_tonumber(L, 4);
	
	midi_event( NOTE_OFF, 0, (unsigned) dtimestamp, chan, note, velocity);
	return 0;
}

static int alsa_sendprogram(lua_State *L) {
	
	int chan = lua_tointeger(L, 1);
	int program = lua_tointeger(L, 2);
	double dtimestamp = lua_tonumber(L, 3);
	
	midi_event( PROG_CHANGE, 0, dtimestamp, chan, program, 0);
	return 0;
}

static int alsa_queueon(lua_State *L) {
	queue_on();
	return 0;
}

static int alsa_queueoff(lua_State *L) {
	queue_off();
	return 0;
}

static int alsa_tempo(lua_State *L) {
	int bpm = lua_tointeger(L, 1);
	set_tempo( bpm );
	return 0;
}
		
static int alsa_stop(lua_State *L) {
	snd_seq_stop_queue( seq_handle, queue, NULL );
	return 0;
}
		
static int alsa_start(lua_State *L) {
	snd_seq_start_queue( seq_handle, queue, NULL );
	return 0;
}
		
static int alsa_continue(lua_State *L) {
	snd_seq_continue_queue( seq_handle, queue, NULL );
	return 0;
}
		
static int alsa_clear(lua_State *L) {
	queue_clear();
	return 0;
}
		
static int alsa_tick(lua_State *L) {
	int events;
	int current_tick = get_tick( &events );
	
	lua_pushnumber( L, (double) current_tick );
	lua_pushinteger( L, events );
	return 2;
}
		
static int alsa_drain(lua_State *L) {

	snd_seq_drain_output( seq_handle );
	return 0;
}

static void handle_midi_event (lua_State *L, unsigned time,
	snd_seq_event_type_t type, snd_seq_ev_note_t note ) {
	
	//fprintf(stderr, "handle_midi_event time=%d\n", time );
	lua_getglobal(L, "alsa");
	if( type == SND_SEQ_EVENT_NOTEON )
		lua_getfield(L, -1, "noteon");
	else 
		if( type == SND_SEQ_EVENT_NOTEOFF )
			lua_getfield(L, -1, "noteoff");
		else {
			fprintf(stderr, "internal error: unknown midi event %d\n", type);
			return;
		}			
	lua_pushinteger(L, note.channel );
	lua_pushinteger(L, note.note );
	lua_pushinteger(L, note.velocity );
	lua_pushnumber(L, (double) time );
	lua_pcall(L, 4, 0, 0);
	lua_pop(L, 1);
	return;
}

// this function called by the update function of love program
static int alsa_update(lua_State *L) {

	snd_seq_event_t *seqevent = NULL;
	while( snd_seq_event_input_pending( seq_handle, 1 ) ) {
		
		snd_seq_event_input( seq_handle, &seqevent );
		switch( seqevent->type ) {
			case SND_SEQ_EVENT_NOTEOFF:
				if( metronome && seqevent->source.client == snd_seq_client_id( seq_handle )) {
					unsigned tick = seqevent->time.tick;
					snd_seq_tick_time_t r = tick % TICKS_PER_QUARTER;
					//fprintf(stderr,"r=%d\n", r);
					midi_event( NOTE_ON, 0, tick + TICKS_PER_QUARTER - r, 9, 41, 90 );
					midi_event( NOTE_OFF, 1, tick + TICKS_PER_QUARTER - r + 1, 9, 41, 90 );
					snd_seq_drain_output( seq_handle );

					lua_getglobal(L, "alsa");
					lua_getfield(L, -1, "click");
					lua_pushnumber(L, (double) tick );
					lua_pcall(L, 1, 0, 0);
					lua_pop(L, 1);					
					break;
				} // fall thru
			case SND_SEQ_EVENT_NOTEON:
				handle_midi_event( L, seqevent->time.tick, seqevent->type, seqevent->data.note );
				break;
			case SND_SEQ_EVENT_CONTROLLER: break;
			default:
			  fprintf(stderr, "unknown sequencer event type %d\n", seqevent->type);
		}		
	}

	return 0;
}	
	
static int alsa_metronome(lua_State *L) {

	snd_seq_tick_time_t tick, r;
	int ev;
	
	metronome = lua_toboolean(L, 1);
	if( metronome ) {
		tick = get_tick(&ev);
		r = tick % TICKS_PER_QUARTER;
		midi_event( NOTE_ON, 0, tick + TICKS_PER_QUARTER - r, 9, 41, 90 );
		midi_event( NOTE_OFF, 1, tick + TICKS_PER_QUARTER - r + 1, 9, 41, 90 );
		snd_seq_drain_output( seq_handle );
	}
	return 0;
}

static const struct luaL_Reg mylib [] = {
	{"init", alsa_init},
	{"close", alsa_close},
	{"noteon", alsa_noteon},
	{"noteoff", alsa_noteoff},
	{"click", alsa_click},
	{"program", alsa_program},
	{"sendnoteon", alsa_sendnoteon},
	{"sendnoteoff", alsa_sendnoteoff},
	{"sendprogram", alsa_sendprogram},
 	{"queueon", alsa_queueon},
	{"queueoff", alsa_queueoff},
	{"tempo", alsa_tempo},
	{"start", alsa_start},
	{"stop", alsa_stop},
	{"continue", alsa_continue},
	{"clear", alsa_clear},
	{"tick", alsa_tick},
	{"drain", alsa_drain},
	{"update", alsa_update},
	{"metronome", alsa_metronome},
	{NULL, NULL}
};

int luaopen_libluaalsa( lua_State *L ) {
    luaL_openlib(L, "alsa", mylib, 0);
    return 1;
}

