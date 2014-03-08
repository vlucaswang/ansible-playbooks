#-------------------------------------------------------------------------------
# Copyright (C) by EMC Corporation, 2002
# All rights reserved.
#-------------------------------------------------------------------------------

# parses out executable name from a command

{  ns = split($0,a,"|")
   for (i=1; i<=ns;i++){
      ns2 = split(a[i],b)
      ns3 = split(b[1],c,"/")
      print c[ns3]
   }
}
