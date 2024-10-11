case "$1" in
  start)
  	start-stop-daemon -S -q -a /usr/bin/aesdsocket
	;;
  stop)
  	start-stop-daemon -K -q -a /usr/bin/aesdsocket
	;;
  *)
	echo "Usage: $0 {start|stop}"
	exit 1
esac

exit $?