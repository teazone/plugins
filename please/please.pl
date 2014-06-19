package Please;

# Perl includes
use strict;
use Data::Dumper;
use Storable;

# Kore includes
use Plugins;

Plugins::register("Please", "Everything Please?", \&unload);
my $hooks = Plugins::addHooks(["packet_pubMsg", \&parseChat],
								["packet_partyMsg", \&parseChat],
								["packet_guildMsg", \&parseChat],
								["packet_selfChat", \&parseChat],
								["packet_privMsg", \&parseChat]);

								
sub unload
{
	Plugins::delHooks($hooks);
}

sub parseChat
{
	my($hook, $args) = @_;	
	my $chat = Storable::dclone($args);
	
	# selfChat returns slightly different arguements, let's fix that
	if($hook eq 'packet_selfChat')
	{
		$chat->{Msg} = $chat->{msg};
		$chat->{MsgUser} = $chat->{user};
	}	
	
	if($chat->{Msg} =~ m/p+l+e+a+s+e*/ and $chat->{Msg} =~ m/invite|party/)
	{
		# Sanitize usernames to prevent command execution xD
		$chat->{MsgUser} =~ s/;/\\;/g;
		Commands::run("party request $chat->{MsgUser}");
	}	
}

1;