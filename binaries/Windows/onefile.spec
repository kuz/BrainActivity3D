# -*- mode: python -*-
a = Analysis(['../../brainactivity.py'],
             hiddenimports=['greenlet', 'sklearn.utils.sparsetools._graph_validation', 'sklearn.utils.sparsetools._graph_tools', 'scipy.special._ufuncs_cxx', 'sklearn.utils.lgamma', 'sklearn.utils.weight_vector'],
             hookspath='.',
             runtime_hooks=None)
pyz = PYZ(a.pure)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          [('./data/201305182224-DF-facial-3-420.csv', '../../data/201305182224-DF-facial-3-420.csv', 'DATA')],
          [('./model/brain_20k_colored_properly.obj', '../../model/brain_20k_colored_properly.obj', 'DATA')],
          [('brain_fragment_shader.glsl', '../../brain_fragment_shader.glsl', 'DATA')],
          [('brain_vertex_shader.glsl', '../../brain_vertex_shader.glsl', 'DATA')],
          a.zipfiles,
          a.datas,
          name='brainactivity.exe',
          debug=False,
          strip=None,
          upx=True,
          console=True )