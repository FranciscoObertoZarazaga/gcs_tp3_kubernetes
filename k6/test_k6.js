import http from 'k6/http';
import { sleep, check } from 'k6';

// Configuración del test
export let options = {
  vus: 10000,         // 10k usuarios simultáneos
  duration: '600s', // durante 60 segundos
};

// Función principal (lo que cada usuario hace)
export default function () {
  let res = http.get('http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/app1/ping/');

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 300ms': (r) => r.timings.duration < 300,
  });

  sleep(1);
}