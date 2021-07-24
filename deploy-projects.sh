#!/bin/bash
echo "Starting OpenShift project bookinfo and bookretail-istio-system."
echo "Please wait.........................."


oc new-project bookretail-istio-system --display-name="Service Mesh System"
sleep 1s
echo "Waiting for create new project bookretail-istio-system ..."
echo "Please wait.........................."


oc new-project bookinfo
sleep 1s
echo "Waiting for create new project bookinfo ..."
echo "Please wait.........................."


oc apply -f service-mesh-control-plane.yaml -n bookretail-istio-system
sleep 1s
echo "Waiting for create new project bookretail-istio-system ..."
echo "Please wait.........................."


oc apply -f service-mesh-roll.yaml -n bookretail-istio-system
sleep 1s
echo "Waiting for create service mesh member roll fot  bookretail-istio-system ..."
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

#oc label namespace bookinfo istio-injection=enabled --overwrite
#sleep 2s
#echo "Waiting for create label istio-injection=enabled in  bookinfo ..."
#echo "Please wait.........................."

oc apply -f https://raw.githubusercontent.com/istio/istio/1.6.0/samples/bookinfo/platform/kube/bookinfo.yaml -n bookinfo
sleep 20s
echo "Waiting for create app bookinfo ..."
echo "Please wait.........................."


oc expose service productpage
sleep 1s
echo "Waiting for create router for  bookinfo ... "
echo "Please wait.........................."


oc apply -f bookinfo-router.yaml -n bookretail-istio-system
echo "Waiting for create router for bookretail-istio-system ... "
echo "Please wait.........................."


oc apply -f injection-template.yaml -n bookinfo
sleep 10s
echo -n "Waiting for add  injection sidecar for app bookinfo ..."
echo "Please wait.........................."


oc apply -f bookinfo-gateway.yaml -n bookinfo
sleep 5s
echo "Waiting for create gateway and virtual service in bookinfo ..."
echo ""

export GATEWAY_URL=$(oc get -n bookretail-istio-system route istio-ingressgateway -o jsonpath='{.spec.host}')
echo "Waiting for export Gateway URL ..."
echo ""

export ROUTER_URL=$(oc get -n bookinfo route productpage -o jsonpath='{.spec.host}')
echo "Waiting for export Gateway URL ..."
echo ""

echo $GATEWAY_URL
echo $ROUTER_URL


oc apply -f bookinfo-destinationrule.yaml -n bookinfo
sleep 1s
echo "Waiting for create destination rule in  bookinfo ..."
echo ""

for i in {1..5}; do sleep 1.0; curl -I $ROUTER_URL/productpage; done
echo "Waitint for curl $ROUTER_URL/productpage ..."
for i in {1..10}; do sleep 1.0; curl -I $ROUTER_URL/productpage?u=normal; done
echo "Waitint for curl $ROUTER_URL/productpage?u=normal"
for i in {1..10}; do sleep 1.0; curl -I $ROUTER_URL/productpage?u=test; done
echo "Waitint for curl $ROUTER_URL/productpage?u=test"
for i in {1..10}; do sleep 1.0; curl -I $GATEWAY_URL/productpage; done
echo "Waitint for curl $ROUTER_URL/productpage"



#oc create secret generic cacerts -n bookretail-istio-system --from-file=ca-cert.pem --from-file=ca-key.pem --from-file=root-cert.pem --from-file=cert-chain.pem
#sleep 1 &
#echo "Waiting for create label istio-injection=enabled in  bookinfo ..."
#echo ""

oc apply -f bookinfo-mutual-mtls.yaml -n bookinfo
sleep 1s
echo "Waiting for create mutual-mtls  bookinfo ..."
echo ""

for i in {1..10}; do sleep 1.0; curl -I $GATEWAY_URL/productpage; done

oc apply -f bookinfo-destinationrule-mtls.yaml -n bookinfo
sleep 1s
echo "Waiting for create destination rule in  bookinfo ..."
echo ""

for i in {1..10}; do sleep 1.0; curl -I $GATEWAY_URL/productpage; done

export BOOKINFO_GATEWAY_URL=$(oc get route -n bookretail-istio-system | grep istio-ingressgateway-secure | awk -F ' ' '{print $2}')
echo ""
echo ""
echo "Red Hat OpenShift Service Mesh and bookinfo has been deployed!"
echo "Test the bookinfo application out at: http://${BOOKINFO_GATEWAY_URL}/productpage"
echo "Note: It may take a few moments for everything to deploy before the URL above is active."
