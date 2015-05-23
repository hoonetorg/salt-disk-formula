disk_lvm__pkg_lvm2:
  pkg:
    - name: lvm2
    - installed
{% set slsrequires =salt['pillar.get']('disk:lvm:slsrequires', False) %}
{% if slsrequires is defined and slsrequires %}
    - require:
{% for slsrequire in slsrequires %}
      - {{slsrequire}}
{% endfor %}
{% endif %}

{% for vg , vg_data in salt['pillar.get']('disk:lvm:vgs', {}).items()|sort %}
{% if vg_data.pvs is defined and vg_data.pvs and vg_data.lvs is defined and vg_data.lvs %}

{% for pv in vg_data.pvs|sort %}
disk_lvm__pv_{{pv}}:
  lvm.pv_present:
    - name: {{pv}}
    - require:
      - pkg: disk_lvm__pkg_lvm2
{% if vg_data.requires is defined and vg_data.requires %}
{% for vgrequire in vg_data.requires %}
      - {{vgrequire}}
{% endfor %}
{% endif %}

{% endfor %}

disk_lvm__vg_{{vg}}:
  lvm.vg_present:
    - name: {{vg}}
    - devices: {% for pv in vg_data.pvs|sort -%}{{ pv }}{% if loop.last %}{%else%},{% endif %}{% endfor %} 
    - require:
{% for pv in vg_data.pvs|sort %}
      - lvm: disk_lvm__pv_{{pv}}
{% endfor -%}

{% for lv , lv_data in vg_data.lvs.items()|sort %}
disk_lvm__lv_{{vg}}_{{lv}}:
  lvm.lv_present:
    - name: {{lv}}
    - vgname: {{vg}}
{% if lv_data.size is defined and lv_data.size %}
    - size: {{lv_data.size}}
{% endif %} 
{% if lv_data.extents is defined and lv_data.extents %}
    - extents: {{lv_data.extents}}
{% endif %} 
    - require:
      - lvm: disk_lvm__vg_{{vg}}


disk_lvm__cmd_vgchange_aey_{{vg}}_{{lv}}:
  cmd.run:
    - name: lvchange -aey {{vg}}/{{lv}}
    - unless: test -L /dev/{{vg}}/{{lv}}
    - require:
      - lvm: disk_lvm__lv_{{vg}}_{{lv}}
{% endfor %}

{% endif %} 
{% endfor %}
