import Immutable from 'immutable'
import {
  ContentStartEnd,
  findContentEndEntities,
  findContentStartEntities,
  findLinkEntities,
  Link
} from 'client/components/rich_text2/utils/decorators.coffee'

export const inlineStyles = (layout, hasFeatures) => {
  // for menu display only
  const styles = [
    {label: 'B', name: 'BOLD'},
    {label: 'I', name: 'ITALIC'}
  ]
  if (layout === 'standard') {
    styles.push({label: ' S ', name: 'STRIKETHROUGH'})
  }
  return styles
}

export const blockTypes = (layout, hasFeatures) => {
  // for menu display only
  const blocks = [
    {label: 'H2', name: 'header-two'},
    {label: 'H3', name: 'header-three'},
    {name: 'unordered-list-item'}
  ]
  if (layout === 'feature') {
    blocks.unshift({label: 'H1', name: 'header-one'})
  }
  if (layout === 'classic') {
    blocks.push({name: 'ordered-list-item'})
  }
  if (hasFeatures) {
    blocks.push({name: 'blockquote'})
  }
  return blocks
}

export const blockRenderMap = (layout, hasFeatures) => {
  // declares blocks available to the editor
  if (!hasFeatures) {
  // classic, partners
    return Immutable.Map({
      'header-two': {element: 'h2'},
      'header-three': {element: 'h3'},
      'unordered-list-item': {element: 'li'},
      'ordered-list-item': {element: 'li'},
      'unstyled': {element: 'p'}
    })
  }
  if (layout === 'feature') {
    return Immutable.Map({
      'header-one': { element: 'h1' },
      'header-two': {element: 'h2'},
      'header-three': {element: 'h3'},
      'blockquote': {element: 'blockquote'},
      'unordered-list-item': {element: 'li'},
      'ordered-list-item': {element: 'li'},
      'unstyled': {element: 'p'}
    })
  } else {
    // standard, classic on internal channels
    return Immutable.Map({
      'header-two': {element: 'h2'},
      'header-three': {element: 'h3'},
      'blockquote': {element: 'blockquote'},
      'unordered-list-item': {element: 'li'},
      'ordered-list-item': {element: 'li'},
      'unstyled': {element: 'p'}
    })
  }
}

export const decorators = (layout) => {
  const decorators = [
    {
      strategy: findLinkEntities,
      component: Link
    }
  ]
  if (layout === 'feature') {
    decorators.push({
      strategy: findContentStartEntities,
      component: ContentStartEnd
    })
    decorators.push({
      strategy: findContentEndEntities,
      component: ContentStartEnd
    })
  } else if (layout === 'standard') {
    decorators.push({
      strategy: findContentEndEntities,
      component: ContentStartEnd
    })
  }
  return decorators
}
