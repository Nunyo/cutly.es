#!/usr/bin/perl
# Acortador de URLS CUTLY
# Nuño López Ansótegui
# 04/07/2015
# Acorta URLs proporcionadas, dando la opción de elegir un alias personalizado para la nueva URL
#
use CGI qw ( -utf8 );
use CGI::Carp qw(fatalsToBrowser);
use strict;
use warnings;
use Random;

my $q = new CGI;
my $shorten;
my $alias;
my $new_file;
my $url_base = 'http://cutly.es/';
our $large_url;

print
    $q->header('text/html'),
    $q->start_html( -style=>'/css/cutly.css', -title => 'Cutly.es URL Shortener',
                    -meta=>{viewport=>'width=device-width, initial-scale=1, maximum-scale=1'},
                    -script=>[{-code=>g_analytics()},{-src=>'http://ajax.googleapis.com/ajax/libs/jquery/1.8/jquery.min.js'},{-src=>'/js/ZeroClipboard.js'},
                    {-src=>'/js/js.js'}], #js para copiar la nueva URL
                    -head=>[$q->Link({-rel=>'icon',-type=>'image/png',-href=>'/img/cutly_favicon_128.png'}), #favicon
                    $q->meta({-charset=>'utf-8', -http_equiv=>'Content-Type', -content=>'text/html'})
                    ] 
                ), 
    $q->a( {-href => $url_base }, $q->img({-src=>'/img/cutly_head.png'}) ), #cabecera
    $q->h1('Enter/Paste your long URL'),
    $q->start_form(-name=>'shorten', -method=>'POST'),
        $q->table($q->Tr(
                        $q->td(
                            $q->table(
                                $q->Tr(
                                    $q->td($q->textfield(-name=>'large_URL', -size=>'60',-class=>'large_url')), #Aquí se introduce la URL a acortar
                                )
                            ),
                        ),
                        $q->td($q->submit(-name=>'shorten_URL', -value=>'Shorten'))
                    ),
                    $q->Tr(
                        $q->td(
                            $q->table(
                                $q->Tr(
                                    $q->td($q->p('Custom alias (optional)')),  #Tenemos la opción de elegir un alias para la nueva URL
                                    $q->td($q->textfield(-name=>'alias', -size=>'15', -class=>'alias',)),
                                )
                            ),
                            $q->p('May contain letters, numbers or/and dashes'),
                        ),
                    ),
                ),
                $q->textfield(-name=>'identity', -class=>'ident'), #Campo no visible para evitar bots 
    $q->end_form;
    if($large_url = $q->param('large_URL') and !$q->param('identity')){ #Comprobamos que el texto no está vacío y no se ha rellenado el campo oculto(bots)
        if($large_url =~ /(https{0,1}:\/\/){0,1}\w+\.[a-zA-Z]+(\/.+){0,1}/i){    #Comprobamos que es una URL válida
            $shorten = shorten_url($q->param('alias')); #Subrutina que crea la URL corta
            print $q->hr,
            $q->td($q->h2('Your new short URL:')),
            $q->table(
                $q->Tr(
                    $q->td($q->p({-class=>'url_short'}, $q->a( {-target=>'_blank', -href => $shorten }, $shorten ))), 
                    # $q->td($q->button({
                            # -id      => 'text-to-copy',
                            # -data-clipboard-text  => $shorten,
                            # -value  => 'COPY'}
                        # )
                    # ),
                    $q->td('<button id="text-to-copy" data-clipboard-text="'.$shorten.'">COPY</button>'), #Damos la opción de copiar la URL corta mediante un botón
                ),
            ),
            $q->hr,
            $q->p({-class=>'url_large'},$q->a( {-href => $large_url }, $large_url )); #Mostramos la URL original
        }else{
            print $q->p({-class=>'not_valid'},'Unable to shorten that link. It is not a valid url.');
        }
    }
    print $q->end_html;

sub shorten_url{
    unless($large_url =~ /https{0,1}:\/\//i){  #Nos aseguramos de introducir la cabecera http
        $large_url = 'http://'.$large_url;
    }
    my $alias = shift;
    my $rand = new Random;
    my $pattern = 'x';
    $rand->{$pattern} = [ 'A'..'Z', 'a'..'z', '0'..'9']; #Creamos un patrón alfanumérico para generar el texto aleatorio
    if($alias){
        $alias =~ s/\W//g; #Elimino cualquier caracter no alfanumérico
        $new_file = $alias.'.pl'; 
    }
    for(my $tries = 1; !$new_file or -e $new_file; ++$tries){  #Nos aseguramos que la nueva URL no existe                                                               
        if($tries>2){                                          #Si en 2 intentos no puede generar un archivo nuevo, incrementamos el numero de caracteres del patrón
            $pattern .= $pattern;
            $tries = 1;
        }
        $alias .= $rand->randpattern($pattern);
        $new_file = $alias.'.pl';
    }
    open (my $new,'>:',$new_file) || die "No se puede abrir el archivo\n";  #Generamos un archivo renombrado con el alias y/o texto aleatorio que redireccionará a la URL larga
    chmod 0755, $new_file;
    print $new qq|#!/usr/bin/perl
use CGI;
print CGI->redirect("|.$large_url.qq|");|;   #Redirección 301
                
    # print $new '<html>        #Redirección convencional con posibilidad de Google Analytics
                    # <head>
                        # <meta http-equiv="Refresh" content="0;url='.$large_url.'">
                        # <script>                              
                          # (function(i,s,o,g,r,a,m){i["GoogleAnalyticsObject"]=r;i[r]=i[r]||function(){
                          # (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
                          # m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
                          # })(window,document,"script","//www.google-analytics.com/analytics.js","ga");

                          # ga("create", "UA-64916086-1", "auto");
                          # ga("send", "pageview");

                        # </script>
                    # </head>'.
                    # '<body>                                               #Retrasar la redireción para mostrar un posible anuncio comercial
                        # <p>Redirecting. If this page appears for more than five seconds, click <a href="'.$large_url.'">here</a></p>
                    # </body>'.
                # '</html>';
    return($url_base.$alias);
    
}

sub g_analytics{
    return "
          (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
          (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
          m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
          })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

          ga('create', 'UA-64916086-1', 'auto');
          ga('send', 'pageview');
          "
    ;
}