# -*- mode: python -*-
a = Analysis(['../../brainactivity.py'],
             hiddenimports=['greenlet', 'sklearn.utils.sparsetools._graph_validation', 'sklearn.utils.sparsetools._graph_tools', 'scipy.special._ufuncs_cxx', 'sklearn.utils.lgamma', 'sklearn.utils.weight_vector'],
             hookspath=None,
             runtime_hooks=None)
pyz = PYZ(a.pure)
exe = EXE(pyz,
          a.scripts,
          exclude_binaries=True,
          name='brainactivity.exe',
          debug=False,
          strip=None,
          upx=True,
          console=True,)
coll = COLLECT(exe,
               a.binaries,
               [('./data/201305182224-DF-facial-3-420.csv', '../../data/201305182224-DF-facial-3-420.csv', 'DATA')],
               [('./model/brain_20k_colored_properly.obj', '../../model/brain_20k_colored_properly.obj', 'DATA')],
               [('brain_fragment_shader.glsl', '../../brain_fragment_shader.glsl', 'DATA')],
               [('brain_vertex_shader.glsl', '../../brain_vertex_shader.glsl', 'DATA')],
               a.zipfiles,
               a.datas,
               strip=None,
               upx=True,
               name='brainactivity')
