package Please;

# Perl includes
use strict;
use Data::Dumper;
use Storable;
use List::MoreUtils;

# Kore includes
use Plugins;
use Globals;
use Match;

our $please = {};
our $party = ['Fiolina', 'Dowlie', 'SourSadnessBear', 'Goddess Etro', 'One Man Band', 'Faye Romani', 'Friendly', 'Librarianna', 'Poof~', 'Tea Zone'];


Plugins::register("Please", "Everything Please?", \&unload);
my $hooks = Plugins::addHooks(["packet_pubMsg", \&parseChat],
                                ["packet_partyMsg", \&parseChat],
                                ["packet_guildMsg", \&parseChat],
                                ["packet_selfChat", \&parseChat],
                                ["packet_privMsg", \&parseChat],
                                ["packet/deal_begin", \&deal_begin],
                                ["packet/deal_finalize", \&deal_finalize],
                                ["packet/party_join", \&party_handler]);

                                
sub unload
{
    Plugins::delHooks($hooks);
}

sub parseChat
{
    my($hook, $args) = @_;	
    my $chat = Storable::dclone($args);
    my $time = Time::HiRes::time();
    
    # selfChat returns slightly different arguements, let's fix that
    if($hook eq 'packet_selfChat')
    {
        $chat->{Msg} = $chat->{msg};
        $chat->{MsgUser} = $chat->{user};
    }	

    # Sanitize usernames to prevent command execution xD
    $chat->{MsgUser} =~ s/;/\\;/g;
    
    if($chat->{Msg} =~ m/p+l+e+a+s+e*/i)
    {
        $please->{$chat->{MsgUser}}->{timeout} = $time + 30;
    }
    
    if($chat->{Msg} =~ m/\b(invite|party)\b/i and $please->{$chat->{MsgUser}}->{timeout} > $time)
    {
        Commands::run("party request $chat->{MsgUser}");
    }
    
    if($chat->{Msg} =~ m/\bdeal\b/i and $please->{$chat->{MsgUser}}->{timeout} > $time)
    {
        my $player = Match::player($chat->{MsgUser});
        
        if($player)
        {
            Commands::run("deal $player->{binID}");
        }
    }
        
    if($chat->{Msg} =~ m/\b(sit|stand|kis|lv|heh|no1|rice|gg|fsh|awsm|slur|ho|thx|omg|go|sob|pif|meh|shy|spin|fsh|sigh|dum|hum|oops|spit|panic|follow|look (?:[0-9]+))\b/i and $please->{$chat->{MsgUser}}->{timeout} > $time)
    {
        my ($request, $option) = split(' ', lc($1));

        if($request eq "sit" or $request eq "stand")
        {
            Commands::run($request);
        }
        elsif($request eq "follow")
        {
            if($config{please_follow})
            {
                Commands::run("follow $chat->{MsgUser}");
            }
        }
        elsif($request eq "look")
        {
            Commands::run("$request $option");
        }
        else
        {
            Commands::run("e $request");
        }
    }
}

sub deal_begin
{
    my($hook, $args) = @_;
    
    if($args->{type} == 3 and $config{autodeal})
    {
        # Immediately finalize the deal once opened
        $messageSender->sendDealFinalize();
    }
}

sub deal_finalize
{
    my($hook, $args) = @_;
    
    if($args->{type} == 1 and $config{autodeal})
    {
        # Immediately accept the deal
        $messageSender->sendDealTrade();
    }
}

sub party_handler
{
    my($hook, $args) = @_;

    # Type 1 means someone disconnected!
    if($args->{type} == 1)
    {
        # Automatically kick users when they disconnect
        my $index = List::MoreUtils::firstidx { $_ eq $args->{ID} } @partyUsersID;
        my $user = $char->{'party'}{'users'}{$args->{ID}}{'name'};
        
        # Don't kick people from our array of official party members
        unless(in_array($party, $user))
        {
            Commands::run("party kick $index");
        }
    }
}


sub in_array {
    my ($arr,$search_for) = @_;
    foreach my $value (@$arr) {
        return 1 if $value eq $search_for;
    }
    return 0;
}

1;
