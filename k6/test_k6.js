import http from 'k6/http';
import { sleep, check, fail } from 'k6';

// Configuración del test
export let options = {
  vus: 10,
  duration: '600s',
};

const DNS_TARGET = 'http://ingress-nginx-controller.ingress-nginx.svc.cluster.local';
// http.get('http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/app1/ping/');

// ----------------------------------------------
// Función principal (lo que hace cada usuario VU)
// ----------------------------------------------
export default function () {
  let res = http.get(
    'http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/app1/ping/',
    {
      headers: {
        Host: 'localhost'
      }
    }
  );


  // Logs útiles por request
  console.log(`--- REQUEST ---`);
  console.log(`Status: ${res.status}`);
  console.log(`Duration: ${res.timings.duration} ms`);
  console.log(`Body: ${res.body}`);
  console.log(`Error: ${res.error || "none"}`);

  // Opcional: loggear headers
  // console.log(`Headers: ${JSON.stringify(res.headers, null, 2)}`);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 300ms': (r) => r.timings.duration < 300,
  });

  sleep(1);
}
