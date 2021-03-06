package SimpleGitDeploy::Model::SendMessage;

use Modern::Perl;
use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Try::Tiny;
use Mojo::Log;

sub new {
    my ($class, $self) = @_;
    $self = {} unless(ref($self) eq 'HASH');
    bless $self, $class;

    $self->{log} = Mojo::Log->new(path => $self->{"config"}->{"logs"}, level => 'debug');

    return $self;
}


sub send_message {
    my ($self, $res) = @_;

    try {
        my $body = $self->create_body($res);
        if ($self->{config}->{"message_type"} eq "email") {
            foreach my $email (@{$self->{config}->{"emails"}}) {
                my $message = $self->create_email($body, $email);
                sendmail($message);
                $self->{log}->debug('Email sent to '. $email->{"to"});
            }
        }
    } catch {
        my $e = $_;
        $self->{log}->error('Error sending message '. $e);
    }
    
}

sub create_email {
    my $self = shift;
    my ($body, $params) = @_;

    my $message = Email::MIME->create(
        header_str => [
            From    => $params->{"from"},
            To      => $params->{"to"},
            Subject => $params->{"subject"},
        ],
        attributes => {
            encoding => 'quoted-printable',
            charset  => 'UTF-8',
        },

        body_str => $body,
        );

    return $message;
}

sub create_body {
    my $self = shift;
    my ($res) = @_;

    my $body = $self->{config}->{"environment"}." branch ".$self->{config}->{"branch"}." update status: ".$res->{"deployment_status"}->{"state"}."\n";
    $body .= "Updated from ".$res->{"deployment"}->{"payload"}->{"deployd_before"}." to ". $res->{"deployment"}->{"sha"}."\n";

    return $body;
}

1;