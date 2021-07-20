#!/bin/bash
echo "Starting OpenShift project bookinfo and bookretail-istio-system."
echo "Please wait.........................."


oc new-project bookretail-istio-system --display-name="Service Mesh System"
sleep 1 
echo "Waiting for create new project bookretail-istio-system ..."
echo "Please wait.........................."


oc apply -f service-mesh-control-plane.yaml -n bookretail-istio-system
sleep 1 &
echo "Waiting for create new project bookretail-istio-system ..."
echo "Please wait.........................."


#wait for smcp to  install
echo -n "Waiting for smcp to fully install (this will take a few moments) ..."
basic_install_smcp=$(oc get smcp -n bookretail-istio-system service-mesh-installation 2>/dev/null | grep ComponentsReady)
while [ "${basic_install_smcp}" == "" ]
do
    echo -n '.'
    sleep 5
    basic_install_smcp=$(oc get smcp -n bookretail-istio-system  service-mesh-installation 2>/dev/null | grep ComponentsReady)
done
echo "done."


oc new-project bookinfo
sleep 1 &
echo "Waiting for create new project bookinfo ..."
echo "Please wait.........................."


oc label namespace bookinfo istio-injection=enabled --overwrite
sleep 1 &
echo "Waiting for create label istio-injection=enabled in  bookinfo ..."
echo "Please wait.........................."


oc apply -f https://raw.githubusercontent.com/istio/istio/1.6.0/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
sleep 30 &
echo "Waiting for create app bookinfo ..."
echo "Please wait.........................."


#oc delete pod -l app=productpage
#oc delete pod -l app=details
#oc delete pod -l app=reviews
#oc delete pod -l app=ratings
#sleep 5 &
#echo "Waiting for create app bookinfo ..."
#echo "Please wait.........................."

oc expose service productpage
sleep 1 &
echo "Waiting for create router fot  bookinfo ... "
echo "Please wait.........................."

oc apply -f service-mesh-roll.yaml -n bookretail-istio-system
sleep 1 &
echo "Waiting for create service mesh member roll fot  bookretail-istio-system ..."
echo "Please wait.........................."

oc apply -f injection-template.yaml -n bookinfo
sleep 10 &
echo -n "Waiting for add  injection sidecar for app bookinfo ..."
echo "Please wait.........................."


oc apply -f bookinfo-gateway.yaml -n bookinfo
sleep 1 &
echo "Waiting for create label istio-injection=enabled in  bookinfo ..."
echo "Please wait.........................."

oc apply -f bookinfo-destinationrule.yaml -n bookinfo
sleep 1 &
echo "Waiting for create label istio-injection=enabled in  bookinfo ..."
echo "Please wait.........................."


oc create secret generic cacerts -n bookretail-istio-system --from-file=ca-cert.pem --from-file=ca-key.pem --from-file=root-cert.pem --from-file=cert-chain.pem
sleep 1 &
echo "Waiting for create label istio-injection=enabled in  bookinfo ..."
echo "Please wait.........................."
