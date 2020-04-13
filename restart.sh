# chkconfig:   2345 90 10                      

# description:  payservice start

#!/bin/sh
java -jar /data/pay_single/common-msht-web-0.0.1-SNAPSHOT.jar &      
echo $! > /data/pay_single/pid/common-msht-web-0.0.1-SNAPSHOT.pid