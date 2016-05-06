package Vmprobe::Viewer;

use common::sense;

use Curses;
use Curses::UI::AnyEvent;

use Vmprobe::Util;
use Vmprobe::RunContext;

use Vmprobe::DB::Probe;
use Vmprobe::DB::EntryByProbe;
use Vmprobe::DB::Entry;


sub new {
    my ($class, %args) = @_;

    my $self = { summaries => {}, };
    bless $self, $class;



    $self->{cui} = Curses::UI::AnyEvent->new(-color_support => 1, -mouse_support => 0, -utf8 => 1);

    $self->{cui}->set_binding(sub { exit }, "\cC");
    $self->{cui}->set_binding(sub { exit }, "q");

    $self->{main_window} = $self->{cui}->add('main', 'Window');
    $self->{notebook} = $self->{main_window}->add(undef, 'Notebook');
    $self->{notebook}->set_binding('goto_prev_page', KEY_LEFT());
    $self->{notebook}->set_binding('goto_next_page', KEY_RIGHT());
    $self->{notebook}->set_binding(\&close_page, 'x');

    $self->{probes_list_page} = $self->{notebook}->add_page("Probes");
    $self->{probes_list_page_widget} =
        $self->{probes_list_page}->add('probes list page', 'Vmprobe::Viewer::ProbeList', -focusable => 0, viewer => $self, -intellidraw => 1);


    $self->{cui}->draw;
    $self->{cui}->startAsync();

    return $self;
}



sub open_probe_screen {
    my ($self, $probe_id) = @_;

    if (!exists $self->{probe_screens}->{$probe_id}) {
        my $page = $self->{notebook}->add_page($probe_id);
        if (!$page) {
            ## can't fit any more in notebook: FIXME: should indicate error
            $Curses::UI::screen_too_small = 0; ## work around curses::ui freezing up
            return;
        }
        $self->{probe_screens}->{$probe_id} = $page;
        $self->{probe_screen_widgets}->{$probe_id} =
            $self->{probe_screens}->{$probe_id}->add("$probe_id widget", 'Vmprobe::Viewer::Probe', -focusable => 0,
                                                     viewer => $self, probe_id => $probe_id);
    }

    $self->{notebook}->activate_page($probe_id);

    $self->{cui}->draw;
}



sub close_page {
    my ($self) = @_; ## $self is notebook object

    return if @{ $self->{-pages} } <= 1;

    $self->delete_page($self->active_page);
    $self->layout;
    $self->root->draw(1);
}




1;
