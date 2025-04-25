use wayland_client::{
    protocol::{wl_keyboard, wl_seat},
    Connection, Dispatch, QueueHandle, WEnum,
};

use crate::StatusBar;

pub struct Keyboard {
    pub wl_keyboard: Option<wl_keyboard::WlKeyboard>,
}

pub struct Seat {
    pub wl_seat: wl_seat::WlSeat,
    pub keyboard: Option<Keyboard>,
}

impl Dispatch<wl_seat::WlSeat, ()> for StatusBar {
    fn event(
        state: &mut Self,
        _proxy: &wl_seat::WlSeat,
        event: wl_seat::Event,
        _data: &(),
        _conn: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        let Some(seat) = state.seat.as_mut() else {
            return;
        };

        let wl_seat::Event::Capabilities {
            capabilities: WEnum::Value(capabilities),
        } = event
        else {
            return;
        };

        if capabilities.contains(wl_seat::Capability::Keyboard) {
            seat.keyboard = Some(Keyboard {
                wl_keyboard: Some(seat.wl_seat.get_keyboard(qh, ())),
            });
        }
    }
}

impl Dispatch<wl_keyboard::WlKeyboard, ()> for StatusBar {
    fn event(
        _state: &mut Self,
        _proxy: &wl_keyboard::WlKeyboard,
        _event: <wl_keyboard::WlKeyboard as wayland_client::Proxy>::Event,
        _data: &(),
        _conn: &Connection,
        _qhandle: &QueueHandle<Self>,
    ) {
    }
}
