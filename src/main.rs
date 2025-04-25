mod output;
mod seat;
mod wgpu_state;

use calloop::EventLoop;
use calloop_wayland_source::WaylandSource;
use output::wgpu_surface;
use wayland_client::{
    delegate_noop,
    protocol::{wl_compositor, wl_output, wl_registry, wl_seat},
    Connection, Dispatch, QueueHandle,
};
use wayland_protocols::xdg::xdg_output::zv1::client::zxdg_output_manager_v1;
use wayland_protocols_wlr::layer_shell::v1::client::{
    zwlr_layer_shell_v1::{self, Layer},
    zwlr_layer_surface_v1::Anchor,
};
use wgpu_state::WgpuState;

struct StatusBar {
    output_manager: Option<zxdg_output_manager_v1::ZxdgOutputManagerV1>,
    compositor: Option<wl_compositor::WlCompositor>,
    layer_shell: Option<zwlr_layer_shell_v1::ZwlrLayerShellV1>,
    outputs: Vec<output::Output>,
    seat: Option<seat::Seat>,
    wgpu: wgpu_state::WgpuState,
}

impl StatusBar {
    fn new(conn: &Connection) -> anyhow::Result<Self> {
        Ok(Self {
            seat: None,
            compositor: None,
            output_manager: None,
            layer_shell: None,
            outputs: Vec::new(),
            wgpu: WgpuState::new(conn)?,
        })
    }

    fn render(&self) {
        self.outputs.iter().for_each(|output| output.render());
    }
}

fn main() -> anyhow::Result<()> {
    env_logger::init();

    let conn = Connection::connect_to_env().expect("Connection to wayland failed");
    let display = conn.display();

    let event_queue = conn.new_event_queue();
    let qh = event_queue.handle();

    let mut event_loop = EventLoop::try_new()?;
    let mut status_bar = StatusBar::new(&conn)?;

    WaylandSource::new(conn, event_queue)
        .insert(event_loop.handle())
        .map_err(|e| anyhow::anyhow!("Failed to insert Wayland source: {}", e))?;

    _ = display.get_registry(&qh, ());

    event_loop.run(None, &mut status_bar, |_| {})?;

    Ok(())
}

impl Dispatch<wl_registry::WlRegistry, ()> for StatusBar {
    fn event(
        state: &mut Self,
        registry: &wl_registry::WlRegistry,
        event: wl_registry::Event,
        _data: &(),
        _conn: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        match event {
            wl_registry::Event::Global {
                name,
                interface,
                version,
            } => match interface.as_str() {
                "wl_compositor" => {
                    state.compositor = Some(registry.bind::<wl_compositor::WlCompositor, _, _>(
                        name,
                        version,
                        qh,
                        (),
                    ));
                }
                "zxdg_output_manager_v1" => {
                    state.output_manager = Some(
                        registry.bind::<zxdg_output_manager_v1::ZxdgOutputManagerV1, _, _>(
                            name,
                            version,
                            qh,
                            (),
                        ),
                    );
                }
                "zwlr_layer_shell_v1" => {
                    state.layer_shell = Some(
                        registry.bind::<zwlr_layer_shell_v1::ZwlrLayerShellV1, _, _>(
                            name,
                            version,
                            qh,
                            (),
                        ),
                    );
                }
                "wl_seat" => {
                    let seat = registry.bind::<wl_seat::WlSeat, _, _>(name, version, qh, ());

                    state.seat = Some(seat::Seat {
                        wl_seat: seat,
                        keyboard: None,
                    });
                }
                "wl_output" => {
                    let output = registry.bind::<wl_output::WlOutput, _, _>(name, version, qh, ());

                    if let (Some(compositor), Some(layer_shell), Some(output_manager)) = (
                        state.compositor.as_ref(),
                        state.layer_shell.as_ref(),
                        state.output_manager.as_ref(),
                    ) {
                        let surface = compositor.create_surface(qh, ());

                        let layer_surface = layer_shell.get_layer_surface(
                            &surface,
                            Some(&output),
                            Layer::Top,
                            "status bar".to_string(),
                            qh,
                            (),
                        );
                        layer_surface.set_size(1, 1);
                        layer_surface.set_anchor(Anchor::Top);
                        surface.commit();

                        let xdg_output = output_manager.get_xdg_output(&output, qh, ());

                        let Ok(wgpu_surface) = wgpu_surface::WgpuSurface::new(
                            &surface,
                            state.wgpu.raw_display_handle,
                            &state.wgpu.instance,
                        ) else {
                            return;
                        };

                        state.outputs.push(output::Output::new(
                            output,
                            xdg_output,
                            surface,
                            layer_surface,
                            name,
                            wgpu_surface,
                        ));
                    }
                }
                _ => {}
            },
            wl_registry::Event::GlobalRemove { name } => {
                let index = state
                    .outputs
                    .iter()
                    .enumerate()
                    .find(|(_, output)| output.info.id == name)
                    .map(|(index, _)| index);

                if let Some(index) = index {
                    state.outputs.swap_remove(index);
                }
            }
            _ => unreachable!(),
        }
    }
}

delegate_noop!(StatusBar: zxdg_output_manager_v1::ZxdgOutputManagerV1);
delegate_noop!(StatusBar: zwlr_layer_shell_v1::ZwlrLayerShellV1);
delegate_noop!(StatusBar: wl_compositor::WlCompositor);
