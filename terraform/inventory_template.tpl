%{ for idx, ip in cp_ips }
k8s-cp-${format("%02d", idx + 1)} ansible_host=${ip} ansible_become=true
%{ endfor }

%{ for idx, ip in worker_ips }
k8s-wk-${format("%02d", idx + 1)} ansible_host=${ip} ansible_become=true
%{ endfor }

[kube_control_plane]
%{ for i in range(cp_count) }
k8s-cp-${format("%02d", i + 1)}
%{ endfor }

[etcd]
%{ for i in range(cp_count) }
k8s-cp-${format("%02d", i + 1)}
%{ endfor }

[kube_node]
%{ for i in range(worker_count) }
k8s-wk-${format("%02d", i + 1)}
%{ endfor }

[k8s_cluster:children]
kube_node
kube_control_plane
